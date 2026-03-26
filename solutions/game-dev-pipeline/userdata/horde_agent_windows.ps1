<#
.SYNOPSIS
    Horde Build Agent Setup — Windows Server 2022
    Runs on first boot of Horde build agent EC2 instances (launched by ASG).

.DESCRIPTION
    This script is rendered by Terraform templatefile() and injected as
    base64-encoded user data into the ASG launch template.

    What it does:
      1.  Installs Chocolatey package manager
      2.  Installs build tools: Git, VS 2022 Build Tools (MSVC + Windows SDK)
      3.  Installs AWS CLI v2 and .NET 8 runtime (required by Horde Agent)
      4.  Installs Docker Desktop for container-based build steps
      5.  Authenticates Docker with Amazon ECR
      6.  Configures the Horde Agent with server URL and agent properties
      7.  Installs and starts the Horde Agent as a Windows Service
      8.  Configures CloudWatch Agent for build metrics

    Variables injected by Terraform templatefile():
      ${horde_server_url}  — e.g. https://horde.games.example.com
      ${ecr_registry}      — e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com

.NOTES
    Run context: SYSTEM account, EC2 user data (runs once on first boot)
    Logs: C:\Windows\Temp\horde-agent-setup.log
#>

param(
    [string]$HordeServerUrl = "${horde_server_url}",
    [string]$EcrRegistry    = "${ecr_registry}",
    [string]$AgentName      = $env:COMPUTERNAME
)

# ---------------------------------------------------------------------------
# Logging helper
# ---------------------------------------------------------------------------
$LogFile = "C:\Windows\Temp\horde-agent-setup.log"
function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Line = "[$Timestamp] $Message"
    Write-Host $Line
    Add-Content -Path $LogFile -Value $Line
}

Write-Log "==> Starting Horde Build Agent setup on $AgentName"
Write-Log "==> Horde Server: $HordeServerUrl"
Write-Log "==> ECR Registry: $EcrRegistry"

# ---------------------------------------------------------------------------
# 1. Chocolatey
# ---------------------------------------------------------------------------
Write-Log "==> Installing Chocolatey"
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
try {
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Log "  Chocolatey installed successfully"
} catch {
    Write-Log "ERROR: Chocolatey installation failed: $_"
    exit 1
}

# Refresh PATH so choco is available immediately
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco -ErrorAction SilentlyContinue).Path)\..\.."
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1" -ErrorAction SilentlyContinue
refreshenv

# ---------------------------------------------------------------------------
# 2. Build tools — Visual Studio 2022 Build Tools with MSVC + Windows SDK
#    Required to compile Unreal Engine C++ projects
# ---------------------------------------------------------------------------
Write-Log "==> Installing Visual Studio 2022 Build Tools"
choco install -y visualstudio2022buildtools `
    --package-parameters "--add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --includeRecommended --passive --norestart"

# ---------------------------------------------------------------------------
# 3. Git, AWS CLI, .NET 8 runtime
# ---------------------------------------------------------------------------
Write-Log "==> Installing Git, AWS CLI, and .NET 8 runtime"
choco install -y git --params "/GitAndUnixToolsOnPath"
choco install -y awscli
choco install -y dotnet-8.0-runtime

# Refresh PATH
refreshenv

# ---------------------------------------------------------------------------
# 4. Docker (for container-based Horde steps)
# ---------------------------------------------------------------------------
Write-Log "==> Installing Docker Engine (Windows containers)"
Install-WindowsFeature -Name Containers -Restart:$false -ErrorAction SilentlyContinue
choco install -y docker-desktop --ignore-checksums
Write-Log "  Docker installed — will be available after restart if needed"

# ---------------------------------------------------------------------------
# 5. Authenticate Docker with ECR
# ---------------------------------------------------------------------------
Write-Log "==> Authenticating Docker with ECR registry: $EcrRegistry"
$Region = (Invoke-WebRequest -Uri "http://169.254.169.254/latest/meta-data/placement/region" -UseBasicParsing).Content.Trim()
try {
    $EcrPassword = & aws ecr get-login-password --region $Region
    $EcrPassword | docker login --username AWS --password-stdin $EcrRegistry
    Write-Log "  ECR authentication successful"
} catch {
    Write-Log "WARNING: ECR authentication failed (Docker may not be running yet): $_"
}

# ---------------------------------------------------------------------------
# 6. Horde Agent installation
# ---------------------------------------------------------------------------
$HordeAgentDir   = "C:\HordeAgent"
$HordeWorkDir    = "C:\HordeWork"
$HordeLogsDir    = "C:\HordeLogs"

Write-Log "==> Creating Horde Agent directories"
New-Item -ItemType Directory -Force -Path $HordeAgentDir  | Out-Null
New-Item -ItemType Directory -Force -Path $HordeWorkDir   | Out-Null
New-Item -ItemType Directory -Force -Path $HordeLogsDir   | Out-Null

# Determine physical resources for agent registration
$TotalRamGb = [Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$CpuCount   = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum

Write-Log "==> Agent resources: ${CpuCount} vCPUs, ${TotalRamGb} GB RAM"

# Write agent configuration (appsettings.json — Horde Agent .NET format)
$AgentConfig = [ordered]@{
    Horde = [ordered]@{
        Server    = $HordeServerUrl
        WorkingDir = $HordeWorkDir
        LogsDir   = $HordeLogsDir
        Name      = $AgentName
        Pools     = @("windows-build", "ue5")
        Properties = [ordered]@{
            OSFamily = "Windows"
            OSVersion = (Get-CimInstance Win32_OperatingSystem).Version
            RAM      = $TotalRamGb
            CPU      = $CpuCount
            HasGPU   = $false
        }
    }
}

$AgentConfigJson = $AgentConfig | ConvertTo-Json -Depth 10
Set-Content -Path "$HordeAgentDir\appsettings.json" -Value $AgentConfigJson -Encoding UTF8
Write-Log "==> Horde Agent configuration written to $HordeAgentDir\appsettings.json"

# ---------------------------------------------------------------------------
# 7. Download Horde Agent binary from ECR / Horde Server
#    Horde Agent can be self-updating when connected to the server.
#    The Horde Server serves the agent binary at /api/v1/tools/horde-agent
# ---------------------------------------------------------------------------
Write-Log "==> Downloading Horde Agent binary from $HordeServerUrl"
$AgentZip = "$HordeAgentDir\HordeAgent.zip"
try {
    Invoke-WebRequest -Uri "$HordeServerUrl/api/v1/tools/horde-agent/deployments?action=download&platform=Win64" `
        -OutFile $AgentZip `
        -UseBasicParsing `
        -TimeoutSec 120
    Expand-Archive -Path $AgentZip -DestinationPath $HordeAgentDir -Force
    Remove-Item -Path $AgentZip -Force
    Write-Log "  Horde Agent binary downloaded and extracted"
} catch {
    Write-Log "WARNING: Could not download Horde Agent binary from server: $_"
    Write-Log "  The agent will self-update on first connection to $HordeServerUrl"
}

# ---------------------------------------------------------------------------
# 8. Install Horde Agent as a Windows Service
# ---------------------------------------------------------------------------
$AgentExe = Get-ChildItem -Path $HordeAgentDir -Filter "HordeAgent.exe" -Recurse | Select-Object -First 1

if ($AgentExe) {
    Write-Log "==> Installing Horde Agent as Windows Service"
    & $AgentExe.FullName service install --service-name "HordeAgent" `
        --display-name "Horde Build Agent" `
        --description "Unreal Engine Horde build agent — managed by AWS Auto Scaling"

    Start-Service -Name "HordeAgent" -ErrorAction SilentlyContinue
    Write-Log "  Horde Agent service started"
} else {
    Write-Log "INFO: HordeAgent.exe not found yet — will start after self-update from $HordeServerUrl"
}

# ---------------------------------------------------------------------------
# 9. CloudWatch Agent for build metrics
# ---------------------------------------------------------------------------
Write-Log "==> Installing and configuring CloudWatch Agent"
choco install -y amazon-cloudwatch-agent -y

$CWAConfig = @{
    metrics = @{
        namespace = "GameDevPipeline/HordeAgents"
        metrics_collected = @{
            cpu        = @{ measurement = @("% Processor Time"); metrics_collection_interval = 60 }
            Memory     = @{ measurement = @("% Committed Bytes In Use"); metrics_collection_interval = 60 }
            LogicalDisk = @{ measurement = @("% Free Space"); resources = @("C:", "D:"); metrics_collection_interval = 60 }
        }
    }
    logs = @{
        logs_collected = @{
            files = @{
                collect_list = @(
                    @{
                        file_path        = "$HordeLogsDir\*.log"
                        log_group_name   = "/ec2/horde-agents"
                        log_stream_name  = "{instance_id}/horde-agent"
                        timezone         = "UTC"
                    }
                )
            }
        }
    }
} | ConvertTo-Json -Depth 10

$CWAConfigPath = "C:\ProgramData\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent.json"
Set-Content -Path $CWAConfigPath -Value $CWAConfig -Encoding UTF8

& "C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1" `
    -a fetch-config -m ec2 -s -c "file:$CWAConfigPath"

Write-Log "==> CloudWatch Agent configured and started"

# ---------------------------------------------------------------------------
# 10. Tag EC2 instance with agent name for visibility in ASG console
# ---------------------------------------------------------------------------
Write-Log "==> Tagging instance with agent name"
$InstanceId = (Invoke-WebRequest -Uri "http://169.254.169.254/latest/meta-data/instance-id" -UseBasicParsing).Content.Trim()
& aws ec2 create-tags --resources $InstanceId --tags "Key=Name,Value=$AgentName" --region $Region

Write-Log "==> [$(Get-Date)] Horde Build Agent setup complete."
Write-Log "==> Agent '$AgentName' will register with: $HordeServerUrl"
Write-Log "==> Monitor agent status at: $HordeServerUrl/agents"
