# Example 3: No-Bastion SSH-Free Access with Session Manager

## Scenario

A company eliminates their EC2 bastion host and replaces it with AWS Systems Manager Session Manager. Engineers access private EC2 instances, EKS nodes, and databases (via port forwarding) without opening any inbound ports. All sessions are logged to S3 and CloudWatch Logs.

Based on the Generali Malaysia EKS security pattern:
> https://aws.amazon.com/blogs/architecture/how-generali-malaysia-optimizes-operations-with-amazon-eks/

---

## Before and After

### Before: Bastion Host Architecture

```
Engineer laptop
    |
    | SSH port 22 (public internet)
    v
Bastion EC2 (public subnet, Elastic IP)
    |
    | SSH port 22 (internal)
    v
Private EC2 instances
```

**Problems with this architecture:**
- Port 22 exposed to internet — constant brute-force and scan attempts.
- SSH keys shared among team members — key rotation is painful.
- Bastion EC2 costs $30–50/month (t3.small with EBS + Elastic IP).
- No session recording — impossible to audit what engineers did.
- Bastion itself becomes a security liability requiring its own patching.

### After: Session Manager Architecture

```
Engineer laptop
    |
    | HTTPS outbound port 443 only
    v
AWS Systems Manager (managed service)
    |
    | Encrypted WebSocket tunnel (no inbound ports on EC2)
    v
Private EC2 instances (no inbound security group rules needed)
```

**Benefits:**
- Zero inbound ports on EC2 — security groups have no port 22 rule.
- No SSH keys — access controlled entirely by IAM policies.
- Full session recording in S3 and real-time streaming to CloudWatch Logs.
- Access scoped by EC2 tags — engineers only reach instances they should.
- Works from AWS Console, AWS CLI, and VS Code Remote SSH extension.
- Supports port forwarding to RDS, Redis, and any private service.

---

## Cost Savings

| Item | Bastion Approach | Session Manager |
|---|---|---|
| EC2 instance | ~$17/month (t3.small) | $0 |
| Elastic IP | $3.60/month | $0 |
| EBS volume | ~$4/month (40 GB gp3) | $0 |
| NAT Gateway (if bastion in public subnet) | ~$32/month | Not needed for SSM |
| Session Manager service | — | Free |
| S3 session logs | — | ~$0.023/GB |
| CloudWatch Logs | — | ~$0.50/GB ingested |
| **Approximate monthly saving** | **$25–55/month** | — |

---

## Required EC2 Instance Setup

### 1. IAM instance profile

Each EC2 instance needs an IAM role with Session Manager permissions. Attach either the module output or the AWS managed policy:

```hcl
resource "aws_iam_role" "ec2" {
  name = "my-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "my-ec2-profile"
  role = aws_iam_role.ec2.name
}
```

### 2. EC2 instance tags for access control

```hcl
resource "aws_instance" "api_server" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = "t3.large"
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  tags = {
    Name                  = "prod-api-server-01"
    Environment           = "prod"
    SessionManagerAccess  = "true"   # Required by engineer IAM policy
  }
}
```

### 3. SSM Agent

Amazon Linux 2023, Amazon Linux 2, and Windows Server AMIs have the SSM Agent pre-installed. For Ubuntu:

```bash
sudo snap install amazon-ssm-agent --classic
sudo systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
sudo systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
```

---

## How to Connect

### Install the Session Manager plugin (once per workstation)

```bash
# macOS
brew install --cask session-manager-plugin

# Linux
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o session-manager-plugin.deb
sudo dpkg -i session-manager-plugin.deb

# Windows — download from:
# https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe
```

### Start an interactive shell session

```bash
aws ssm start-session \
  --target i-0abc1234567890def \
  --region us-east-1
```

This opens a shell directly — no SSH key, no port 22, no bastion.

### List available instances

```bash
aws ssm describe-instance-information \
  --region us-east-1 \
  --query "InstanceInformationList[*].{ID:InstanceId,Name:ComputerName,Ping:PingStatus}" \
  --output table
```

---

## Port Forwarding to RDS (Most Common Use Case)

Engineers can forward a remote RDS/Aurora port to their local machine. This enables `psql`, DBeaver, TablePlus, and any other local DB client to connect to a private RDS instance.

### PostgreSQL / Aurora PostgreSQL

```bash
aws ssm start-session \
  --target i-0abc1234567890def \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{
    "host":            ["fintech-prod.cluster-abc123.us-east-1.rds.amazonaws.com"],
    "portNumber":      ["5432"],
    "localPortNumber": ["15432"]
  }' \
  --region us-east-1
```

Then connect locally:
```bash
psql -h 127.0.0.1 -p 15432 -U app_user -d fintechdb
```

### MySQL / Aurora MySQL

```bash
aws ssm start-session \
  --target i-0abc1234567890def \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{
    "host":            ["mydb.cluster-abc123.us-east-1.rds.amazonaws.com"],
    "portNumber":      ["3306"],
    "localPortNumber": ["13306"]
  }' \
  --region us-east-1
```

### Redis (ElastiCache)

```bash
aws ssm start-session \
  --target i-0abc1234567890def \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{
    "host":            ["fintech-prod.abc123.ng.0001.use1.cache.amazonaws.com"],
    "portNumber":      ["6379"],
    "localPortNumber": ["16379"]
  }' \
  --region us-east-1
```

---

## VS Code Remote SSH over Session Manager

Add this to your `~/.ssh/config`:

```
Host i-* mi-*
  ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p' --region us-east-1"
  User ec2-user
  StrictHostKeyChecking no
```

Then in VS Code: **Remote-SSH: Connect to Host** → type `i-0abc1234567890def`.

Note: This still uses SSH protocol over the SSM tunnel, so the instance needs a running SSH daemon and your public key in `authorized_keys`. For a fully keyless experience, use `aws ssm start-session` directly instead.

---

## Session Logging and Audit

All sessions are automatically recorded when the module's S3 and CloudWatch configuration is applied.

### View active sessions

```bash
aws ssm describe-sessions \
  --state Active \
  --region us-east-1 \
  --query "Sessions[*].{ID:SessionId,Target:Target,Owner:Owner,StartDate:StartDate}" \
  --output table
```

### View session history

```bash
aws ssm describe-sessions \
  --state History \
  --filters Key=Target,Values=i-0abc1234567890def \
  --region us-east-1
```

### Terminate a session (admin)

```bash
aws ssm terminate-session \
  --session-id "alice-0abc123def456789" \
  --region us-east-1
```

### View session logs in CloudWatch

```bash
aws logs get-log-events \
  --log-group-name "/aws/ssm/session-manager/mycompany-prod" \
  --log-stream-name "alice-0abc123def456789" \
  --region us-east-1 \
  --query "events[*].message" \
  --output text
```

---

## Security Hardening

### Require MFA for session start

Add a condition to the engineer IAM policy:

```json
{
  "Condition": {
    "Bool": {
      "aws:MultiFactorAuthPresent": "true"
    },
    "NumericLessThan": {
      "aws:MultiFactorAuthAge": "3600"
    }
  }
}
```

### Restrict by IP (office or VPN)

```json
{
  "Condition": {
    "IpAddress": {
      "aws:SourceIp": ["203.0.113.0/24", "198.51.100.50/32"]
    }
  }
}
```

### Restrict by tag (engineers only access instances they own or are assigned)

The example policy already scopes access by two tags:
- `Environment = prod` — only production instances
- `SessionManagerAccess = true` — only instances explicitly opted in

---

## VPC Endpoints (Private Subnet Without NAT Gateway)

If your EC2 instances are in private subnets without a NAT Gateway, the SSM Agent cannot reach SSM endpoints via the internet. Create three Interface VPC endpoints and one Gateway endpoint:

| Endpoint | Type | Required |
|---|---|---|
| `com.amazonaws.REGION.ssm` | Interface | Yes |
| `com.amazonaws.REGION.ssmmessages` | Interface | Yes |
| `com.amazonaws.REGION.ec2messages` | Interface | Yes |
| `com.amazonaws.REGION.s3` | Gateway | Yes (for session logs) |
| `com.amazonaws.REGION.kms` | Interface | If using KMS encryption |
| `com.amazonaws.REGION.logs` | Interface | If using CloudWatch Logs |

Interface endpoints cost approximately $0.01/hour each (~$7.20/month per endpoint per AZ). Three endpoints across two AZs = ~$43/month — still less than a bastion in many cases, and eliminates the need for a NAT Gateway ($32/month + data transfer).

The VPC endpoint resources are included as commented-out blocks in `main.tf`. Uncomment and fill in your VPC and subnet IDs to enable them.

---

## Deploying

```bash
terraform init
terraform plan
terraform apply
```

After applying:
1. Attach the `session_manager_policy_arn` output to your EC2 instance IAM roles.
2. Attach the `engineer_policy_arn` output to engineer IAM users/roles.
3. Tag EC2 instances with `SessionManagerAccess = true` and `Environment = prod`.
4. Verify instances appear in **Systems Manager → Fleet Manager**.
5. Test with: `aws ssm start-session --target i-0yourinstanceid`
