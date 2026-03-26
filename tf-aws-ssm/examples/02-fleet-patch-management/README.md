# Example 2: Enterprise EC2 Fleet Patch Management

## Scenario

An enterprise runs 200 mixed EC2 instances across three environments. This example implements automated patching using AWS Systems Manager Patch Manager, based on the AWS blog pattern:

> "Patching your Windows EC2 instances using AWS Systems Manager Patch Manager"
> https://aws.amazon.com/blogs/mt/patching-your-windows-ec2-instances-using-aws-systems-manager-patch-manager/

**Fleet composition:**
- 80x Windows Server 2022 (IIS web servers, .NET application servers)
- 120x Amazon Linux 2023 (API servers, Kafka consumers, ML workers)

---

## Patch Baseline Strategy

Six baselines are defined — one per operating system per environment:

| Baseline Key | OS | Environment | Auto-Approve Delay | Scope |
|---|---|---|---|---|
| `al2023-prod` | Amazon Linux 2023 | prod | 7 days (Security), 14 days (Bugfix) | Critical + Important only |
| `al2023-test` | Amazon Linux 2023 | test | 5 days | Critical + Important |
| `al2023-dev` | Amazon Linux 2023 | dev | 3 days | All severities + non-security |
| `windows-prod` | Windows Server | prod | 7 days (Critical/Security), 21 days (Rollups) | CriticalUpdates + SecurityUpdates |
| `windows-test` | Windows Server | test | 5 days | CriticalUpdates + SecurityUpdates |
| `windows-dev` | Windows Server | dev | 3 days | All update classifications |

**Why longer delays in prod?** The auto-approve delay gives your team time to review the AWS security bulletin, check for regressions in dev/test, and validate the patch before it automatically applies to production. AWS's own recommendation for critical production workloads is 7 days minimum.

---

## EC2 Instance Tagging

Every EC2 instance must be tagged correctly for Patch Manager to apply the right baseline and maintenance window.

### Required tags

```
Key: Patch Group
Value: prod-linux | prod-linux-ml | dev-linux | test-linux |
       prod-windows | prod-windows-iis | prod-windows-dotnet |
       dev-windows | test-windows
```

```
Key: Environment
Value: prod | test | dev
```

### Apply tags via AWS CLI

```bash
# Tag a Linux production API server
aws ec2 create-tags \
  --resources i-0abc1234567890def \
  --tags \
    Key="Patch Group",Value="prod-linux" \
    Key="Environment",Value="prod" \
  --region us-east-1

# Tag a Windows IIS server
aws ec2 create-tags \
  --resources i-0def9876543210abc \
  --tags \
    Key="Patch Group",Value="prod-windows-iis" \
    Key="Environment",Value="prod" \
  --region us-east-1
```

### Apply tags via Terraform

```hcl
resource "aws_instance" "api_server" {
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.large"

  tags = {
    Name          = "prod-api-server-01"
    "Patch Group" = "prod-linux"
    Environment   = "prod"
  }
}
```

---

## Maintenance Window Schedule

| Window Name | Cron | UTC Time | Duration | Target |
|---|---|---|---|---|
| `prod-linux-weekly` | `cron(0 2 ? * SUN *)` | Sunday 02:00–06:00 | 4 hours | prod-linux, prod-linux-ml |
| `prod-windows-weekly` | `cron(0 2 ? * SUN *)` | Sunday 02:00–06:00 | 4 hours | prod-windows-* |
| `test-all-saturday` | `cron(0 4 ? * SAT *)` | Saturday 04:00–07:00 | 3 hours | tag:Environment=test |
| `dev-wednesday-daytime` | `cron(0 10 ? * WED *)` | Wednesday 10:00–11:00 | 1 hour | tag:Environment=dev |
| `daily-compliance-scan` | `cron(0 6 * * ? *)` | Daily 06:00 | 2 hours | tag:Environment=prod |

**Window selection rationale:**
- **Sunday 02:00 UTC** = Saturday 10 PM US-East, Saturday 7 PM US-West — lowest production traffic globally.
- **Wednesday 10:00 UTC** for dev = engineers are online, can immediately investigate any patch-related breakage.
- **Daily scan** at 06:00 UTC runs before business hours, results available when engineers start work.

---

## Rate Control: max_concurrency and max_errors

These two parameters prevent a bad patch from taking down your entire fleet simultaneously.

### max_concurrency

Controls how many instances are patched simultaneously. Can be a percentage or absolute number.

```hcl
max_concurrency = "10%"   # Of 120 prod-linux servers, patch 12 at a time
max_concurrency = "50%"   # For test — faster is fine
max_concurrency = "100%"  # For dev — patch all at once
max_concurrency = "10"    # Absolute: exactly 10 servers at a time
```

**Production recommendation:** Start at 10–20% so that if something goes wrong, the majority of the fleet is still serving traffic.

### max_errors

Controls when Patch Manager stops the maintenance window task entirely. Once this threshold is reached, no more instances are patched.

```hcl
max_errors = "5%"    # Stop after 6 of 120 instances fail
max_errors = "20%"   # Test/dev — continue even if 1 in 5 fail
max_errors = "3"     # OT/critical: stop after exactly 3 failures
```

**Two-task pattern (scan then install):**

The `prod-linux-weekly` window runs two tasks:
1. `scan-before-patch` (priority 1): Scans all instances, logs what needs patching. No changes made. Useful for pre-patch visibility.
2. `install-patches` (priority 2): Installs approved patches with `RebootIfNeeded`. Runs after scan completes.

---

## Compliance Monitoring

### Check compliance via AWS Console

1. Open **AWS Systems Manager** → **Patch Manager** → **Compliance reporting**.
2. Filter by **Patch Group** or **Environment** tag.
3. Instances show as **Compliant**, **Non-Compliant**, or **Unknown** (SSM Agent not running).

### Check compliance via CLI

```bash
# List all non-compliant instances in prod
aws ssm describe-instance-patch-states-for-patch-group \
  --patch-group "prod-linux" \
  --region us-east-1 \
  --query "InstancePatchStates[?ComplianceStatus=='NON_COMPLIANT'].{ID:InstanceId,Missing:MissingCount,Failed:FailedCount}" \
  --output table

# Get patch details for a specific instance
aws ssm describe-instance-patches \
  --instance-id i-0abc1234567890def \
  --filters Key=State,Values=Missing,Failed \
  --region us-east-1 \
  --output table

# View maintenance window execution history
aws ssm describe-maintenance-window-executions \
  --window-id mw-0abc123def456789 \
  --region us-east-1
```

### Check scan results before patching

```bash
# Run an on-demand scan (does not install anything)
aws ssm send-command \
  --document-name "AWS-RunPatchBaseline" \
  --targets Key=tag:Patch Group,Values=prod-linux \
  --parameters '{"Operation":["Scan"],"RebootOption":["NoReboot"]}' \
  --region us-east-1
```

---

## Rejected Patches

Some patches are explicitly rejected to prevent known regressions:

**Linux:** `kernel-ml` and `kernel-ml-headers` are rejected because the mainline kernel requires separate validation before being approved for production workloads.

**Windows:** Specific KBs can be listed in `rejected_patches`. This is equivalent to declining an update in WSUS. Rejected patches are never installed regardless of approval rules.

```bash
# Verify a specific KB is rejected
aws ssm get-patch-baseline \
  --baseline-id pb-0abc123def456789 \
  --region us-east-1 \
  --query "RejectedPatches"
```

---

## Deploying

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

After applying:
1. Tag your EC2 instances with the `Patch Group` and `Environment` tags.
2. Verify instances appear in **Patch Manager → Managed Instances**.
3. Run an on-demand scan to validate baseline assignment.
4. Monitor the first maintenance window execution in **Patch Manager → Maintenance Windows**.
