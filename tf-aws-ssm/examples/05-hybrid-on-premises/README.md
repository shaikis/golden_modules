# Example 5: Hybrid Cloud — On-Premises Server Management

## Scenario

A manufacturing company has 50 on-premises Windows servers running SCADA software on the factory floor (OT network). These servers need patching, configuration enforcement, remote access, and compliance reporting — all without a VPN, without exposing RDP, and without disrupting production.

This example registers the factory servers with AWS SSM using Hybrid Activations. Once registered, the servers are managed exactly like EC2 instances: Patch Manager keeps them patched, Session Manager replaces VPN+RDP, State Manager enforces security baselines, and Resource Data Sync exports inventory to S3 for Athena compliance queries.

---

## Architecture

```
Factory Floor (OT Network — no inbound ports allowed)
┌─────────────────────────────────────────────────────┐
│  Windows Server (SCADA)  ──┐                        │
│  Windows Server (HMI)    ──┤                        │
│  Windows Server (Historian)┤  SSM Agent              │
│  ...47 more servers...   ──┘  (outbound HTTPS :443) │
└──────────────────────────────────────┬──────────────┘
                                       │ HTTPS outbound
                                       │ port 443 only
                                       ▼
                            AWS Systems Manager
                            ┌──────────────────────┐
                            │  Fleet Manager        │
                            │  Patch Manager        │
                            │  Session Manager      │
                            │  State Manager        │
                            │  Inventory            │
                            └──────────────────────┘
                                       │
                              ┌────────┼────────┐
                              ▼        ▼        ▼
                             S3   CloudWatch  Athena
                          (logs)  (sessions) (reports)
```

**Key point:** The SSM Agent only makes outbound connections to SSM endpoints on port 443. No inbound firewall rules are required. No VPN tunnel is needed. No cloud-to-factory traffic is initiated by AWS.

---

## Step-by-Step: Register a Windows Server

### 1. Apply Terraform to get the activation credentials

```bash
terraform init
terraform apply

# Retrieve the activation ID and code
ACTIVATION_ID=$(terraform output -raw activation_id)
ACTIVATION_CODE=$(terraform output -raw activation_code)

echo "Activation ID:   $ACTIVATION_ID"
echo "Activation Code: $ACTIVATION_CODE"
```

Keep these values. You need them on each factory server.

### 2. Install the SSM Agent on Windows Server 2022

Open PowerShell as Administrator on the factory server:

```powershell
# Download the SSM Agent installer
$url = "https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/windows_amd64/AmazonSSMAgentSetup.exe"
$installer = "$env:TEMP\AmazonSSMAgentSetup.exe"
Invoke-WebRequest -Uri $url -OutFile $installer

# Install silently
Start-Process -FilePath $installer -ArgumentList "/S" -Wait

# Verify installation
Get-Service AmazonSSMAgent
```

### 3. Register the server with SSM (use your actual values)

```powershell
# Register this server with the SSM Hybrid Activation
cd "C:\Program Files\Amazon\SSM"
.\amazon-ssm-agent.exe -register `
  -code  "YOUR_ACTIVATION_CODE" `
  -id    "YOUR_ACTIVATION_ID" `
  -region "us-east-1"

# Start the agent
Start-Service AmazonSSMAgent
Set-Service AmazonSSMAgent -StartupType Automatic

# Verify registration — should print "Registration successful"
.\amazon-ssm-agent.exe -fingerprint
```

### 4. Tag the server for patch group and inventory targeting

After registration, the server appears in Fleet Manager as `mi-xxxxxxxxxxxxxxxxx`. Tag it:

```bash
# From your workstation (AWS CLI)
aws ssm add-tags-to-resource \
  --resource-type ManagedInstance \
  --resource-id mi-0abc1234567890def \
  --tags \
    Key="Patch Group",Value="factory-windows-ot" \
    Key="SSMActivation",Value="factory-floor" \
    Key="Environment",Value="prod" \
    Key="Building",Value="A" \
    Key="Rack",Value="1" \
  --region us-east-1
```

### 5. Verify the server is online

```bash
aws ssm describe-instance-information \
  --filters Key=ResourceType,Values=ManagedInstance \
  --region us-east-1 \
  --query "InstanceInformationList[*].{ID:InstanceId,Name:ComputerName,Ping:PingStatus,Agent:AgentVersion}" \
  --output table
```

---

## Step-by-Step: Register a Linux Server

For Ubuntu or RHEL on-premises servers:

```bash
# Download and install the SSM Agent
mkdir /tmp/ssm && cd /tmp/ssm
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb

# Register with SSM Hybrid Activation
sudo amazon-ssm-agent -register \
  -code  "YOUR_ACTIVATION_CODE" \
  -id    "YOUR_ACTIVATION_ID" \
  -region "us-east-1"

# Start and enable the agent
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent

# Verify
sudo systemctl status amazon-ssm-agent
```

For Amazon Linux / RHEL / CentOS:

```bash
sudo yum install -y amazon-ssm-agent
sudo amazon-ssm-agent -register \
  -code  "YOUR_ACTIVATION_CODE" \
  -id    "YOUR_ACTIVATION_ID" \
  -region "us-east-1"
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
```

---

## Why Outbound HTTPS Only?

The SSM Agent establishes a WebSocket connection to the following AWS endpoints (all port 443):

| Endpoint | Purpose |
|---|---|
| `ssm.us-east-1.amazonaws.com` | Registration, parameter reads, patch operations |
| `ssmmessages.us-east-1.amazonaws.com` | Session Manager real-time communication |
| `ec2messages.us-east-1.amazonaws.com` | Run Command and State Manager |
| `s3.amazonaws.com` | Agent installer downloads, session log uploads |

The factory firewall needs a single outbound rule:

```
Direction: OUTBOUND
Protocol:  TCP
Port:      443
Destinations:
  *.ssm.us-east-1.amazonaws.com
  *.ssmmessages.us-east-1.amazonaws.com
  *.ec2messages.us-east-1.amazonaws.com
  *.s3.amazonaws.com
```

No inbound rules. No NAT. No VPN. The SSM Agent polls AWS endpoints on a configurable interval (default: 30 seconds) and receives work through the persistent WebSocket.

---

## OT/ICS-Specific Considerations

### Why 14-day patch approval delay (vs 7 days for IT)?

In IT environments, a bad patch causes downtime — frustrating but recoverable. In OT environments, a bad patch can:
- Break communication between the SCADA server and PLCs (Programmable Logic Controllers).
- Interrupt production lines, causing physical equipment damage.
- Violate IEC 62443 change control requirements.

A 14-day delay allows the vendor (Siemens, Rockwell, etc.) to publish compatibility notices and allows the OT team to test the patch on a development copy of the SCADA environment before it reaches production systems.

### Why max_concurrency = "10" (absolute, not percent)?

With 50 factory servers, `"10%"` would mean patching 5 servers simultaneously — too slow. `"10"` means exactly 10 at a time. This is a deliberate choice: if 10 servers reboot simultaneously and something goes wrong with a PLC network segment, the remaining 40 servers are still running and can maintain partial production.

### Why max_errors = "3" (not a percentage)?

Three is the maximum number of failed patches before the maintenance window task stops entirely. In OT environments, three consecutive failures on different servers likely indicates a systemic problem (driver incompatibility, SCADA version mismatch) rather than isolated failures. Stopping early prevents a cascading partial-patch state across the entire floor.

### Rejected patches

Two patches are explicitly rejected:
- `KB5004945` — Known to reset the Siemens WinCC OPC-UA communication settings, breaking PLC data collection.
- `KB4592438` — Causes a timeout in the S7 protocol stack used by Siemens S7-1500 PLCs.

When adding new KBs to the rejected list, document the reason in the comment and in your change management system.

---

## Remote Access via Session Manager (Replaces VPN + RDP)

Engineers connect to factory servers through Session Manager — no VPN connection required, no RDP port exposure.

### Start an interactive PowerShell session

```bash
aws ssm start-session \
  --target mi-0abc1234567890def \
  --region us-east-1
```

This opens a PowerShell prompt on the factory server. The session is logged to S3 and CloudWatch.

### Run a command on all factory servers without opening sessions

```bash
aws ssm send-command \
  --document-name "AWS-RunPowerShellScript" \
  --targets Key=tag:SSMActivation,Values=factory-floor \
  --parameters commands=["Get-Service AmazonSSMAgent | Select-Object Name,Status"] \
  --region us-east-1 \
  --query "Command.CommandId" \
  --output text
```

### View session recordings

```bash
# List recent sessions for a specific managed instance
aws ssm describe-sessions \
  --state History \
  --filters Key=Target,Values=mi-0abc1234567890def \
  --region us-east-1

# View session log in CloudWatch
aws logs get-log-events \
  --log-group-name "/aws/ssm/factory-sessions" \
  --log-stream-name "engineer-0abc123def456789" \
  --region us-east-1 \
  --query "events[*].message" \
  --output text
```

---

## Compliance Reporting via Athena

Resource Data Sync writes inventory data to S3 in a structured format that Athena can query directly.

### Create an Athena table over the inventory data

```sql
CREATE EXTERNAL TABLE ssm_inventory (
  resourceid        STRING,
  resourcetype      STRING,
  capturedtime      STRING,
  schemaversion     STRING,
  content           STRING
)
PARTITIONED BY (accountid STRING, region STRING, resourcetype STRING)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://manufacturing-corp-compliance-inventory/ssm-inventory/factory/'
TBLPROPERTIES ('has_encrypted_data' = 'false');

MSCK REPAIR TABLE ssm_inventory;
```

### Example compliance queries

```sql
-- Find all factory servers missing critical patches
SELECT
  resourceid AS instance_id,
  json_extract_scalar(content, '$.PatchState.InstanceId') AS server,
  json_extract_scalar(content, '$.PatchState.MissingCount') AS missing_patches,
  json_extract_scalar(content, '$.PatchState.LastNoRebootInstallOperationTime') AS last_patched
FROM ssm_inventory
WHERE resourcetype = 'AWS:PatchSummary'
  AND CAST(json_extract_scalar(content, '$.PatchState.MissingCount') AS INTEGER) > 0
ORDER BY CAST(json_extract_scalar(content, '$.PatchState.MissingCount') AS INTEGER) DESC;

-- List all software installed on factory servers (for license audit)
SELECT
  resourceid AS instance_id,
  json_extract_scalar(content, '$.Application.Name') AS software_name,
  json_extract_scalar(content, '$.Application.Version') AS version,
  json_extract_scalar(content, '$.Application.Publisher') AS publisher
FROM ssm_inventory
WHERE resourcetype = 'AWS:Application'
ORDER BY instance_id, software_name;

-- Check which servers last checked in more than 24 hours ago (offline detection)
SELECT
  instanceid AS instance_id,
  computername,
  lastpingdatetime,
  pingstatus
FROM ssm_managed_instance_information
WHERE lastpingdatetime < DATE_ADD('hour', -24, NOW())
ORDER BY lastpingdatetime;
```

---

## Cost: SSM Advanced Instances for On-Premises

On-premises servers registered via Hybrid Activations are classified as **Advanced Instances** in SSM (they cannot use the free Standard tier available to EC2 instances).

| Pricing Item | Rate |
|---|---|
| On-premises managed instance | $0.00695 per instance per hour |
| 50 servers, 1 month (730 hours) | 50 × 0.00695 × 730 = **~$254/month** |
| Session Manager sessions | Free |
| State Manager associations | Free |
| Patch Manager | Free |
| Run Command | Free |

**Cost comparison vs alternatives:**

| Approach | Monthly Cost (50 servers) |
|---|---|
| WSUS server (EC2 m5.large) | ~$70 + EBS + licensing |
| VPN gateway (AWS Site-to-Site) | ~$36 + data transfer |
| Traditional RMM tool (per-agent license) | $200–$500 |
| SSM Hybrid (50 servers) | ~$254 |
| SSM Hybrid (net of WSUS + VPN savings) | ~$148 net new cost |

For 50 servers, SSM Hybrid consolidates WSUS, VPN remote access, configuration management, and compliance reporting into a single managed service.

---

## Deploying

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Get activation credentials
terraform output activation_id
terraform output -raw activation_code  # Sensitive — pipe to a password manager
```

Then register each factory server using the steps in the "Register a Windows Server" section above. The activation expires on `2026-12-31` — update `activation_expiration_date` before then and re-apply.
