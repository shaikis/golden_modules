<powershell>
# Retrieve instance-id for unique hostname using IMDSv2
$MetadataHeaders = @{
  "X-aws-ec2-metadata-token" = (
    Invoke-RestMethod -Method PUT -Uri "http://169.254.169.254/latest/api/token" -Headers @{
      "X-aws-ec2-metadata-token-ttl-seconds" = "21600"
    }
  )
}
$InstanceId = (Invoke-WebRequest -Uri "http://169.254.169.254/latest/meta-data/instance-id" -Headers $MetadataHeaders -UseBasicParsing).Content
$PrivateIp  = (Invoke-WebRequest -Uri "http://169.254.169.254/latest/meta-data/local-ipv4" -Headers $MetadataHeaders -UseBasicParsing).Content
$IpLastOctet = $PrivateIp.Split(".")[-1]
$NewName    = "${hostname_prefix}${hostname_separator}$IpLastOctet"

# Rename computer (takes effect after reboot)
Rename-Computer -NewName $NewName -Force

# Tag this instance in AWS
$Region = (Invoke-WebRequest -Uri "http://169.254.169.254/latest/meta-data/placement/region" -Headers $MetadataHeaders -UseBasicParsing).Content
$AwsCli = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
for ($Attempt = 1; $Attempt -le 5; $Attempt++) {
  & $AwsCli ec2 create-tags `
      --region $Region `
      --resources $InstanceId `
      --tags Key=Name,Value=$NewName Key=Hostname,Value=$NewName

  if ($LASTEXITCODE -eq 0) {
    break
  }

  if ($Attempt -eq 5) {
    Write-Warning "Failed to update EC2 Name tag to $NewName after $Attempt attempts."
  } else {
    Start-Sleep -Seconds 10
  }
}

%{ if bootstrap_enabled }
$BootstrapStateDir = "C:\ProgramData\tf-aws-asg-bootstrap"
New-Item -ItemType Directory -Path $BootstrapStateDir -Force | Out-Null

@'
${bootstrap_context_json}
'@ | Set-Content -Path "$BootstrapStateDir\context.json" -Encoding UTF8

$env:TF_ASG_BOOTSTRAP_CONTEXT_FILE = "$BootstrapStateDir\context.json"
$env:TF_ASG_BOOTSTRAP_HOSTNAME = $NewName

%{ if bootstrap_s3_bucket != "" && bootstrap_s3_key_prefix != "" }
$BootstrapEntrypointDir = Split-Path -Path "${bootstrap_entrypoint}" -Parent
New-Item -ItemType Directory -Path $BootstrapEntrypointDir -Force | Out-Null
& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" s3 sync "s3://${bootstrap_s3_bucket}/${bootstrap_s3_key_prefix}/" "$BootstrapEntrypointDir" --region $Region
if ($LASTEXITCODE -ne 0) { throw "Failed to sync bootstrap content from S3." }
%{ endif }
%{ if bootstrap_s3_bucket != "" && bootstrap_manifest_key != "" }
& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" s3 cp "s3://${bootstrap_s3_bucket}/${bootstrap_manifest_key}" "$BootstrapStateDir\manifest.json" --region $Region
if ($LASTEXITCODE -ne 0) { throw "Failed to download bootstrap manifest from S3." }
$env:TF_ASG_BOOTSTRAP_MANIFEST_FILE = "$BootstrapStateDir\manifest.json"
%{ endif }

if (-not (Test-Path "${bootstrap_entrypoint}")) {
  throw "Bootstrap entrypoint not found at ${bootstrap_entrypoint}"
}

& "${bootstrap_entrypoint}"
if ($LASTEXITCODE -ne 0) { throw "Bootstrap entrypoint failed." }
%{ endif }

${extra_commands}

%{ if domain_name != "" }
# Domain join using credentials stored in Secrets Manager
$SecretValue = (& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" secretsmanager get-secret-value `
    --region $Region `
    --secret-id "${domain_join_secret}" `
    --query SecretString `
    --output text) | ConvertFrom-Json
$DomainUser = "$($SecretValue.username)@${domain_name}"
$DomainPass = ConvertTo-SecureString $SecretValue.password -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential($DomainUser, $DomainPass)
Add-Computer -DomainName "${domain_name}" -Credential $Cred -Restart -Force
%{ else }
Restart-Computer -Force
%{ endif }
</powershell>
<persist>true</persist>
