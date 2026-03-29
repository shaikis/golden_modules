# AWS Systems Manager (SSM) — Comprehensive Terraform Module

Covers all 9 SSM features. Every feature is opt-in. Use one, some, or all together.

---

## Feature Map

| # | Feature | How to enable | AWS Resource |
|---|---------|---------------|--------------|
| 1 | Parameter Store | `parameters = {...}` | `aws_ssm_parameter` |
| 2 | Patch Manager | `create_patch_baselines = true` + `patch_baselines = {...}` | `aws_ssm_patch_baseline` |
| 3 | Maintenance Windows | `maintenance_windows = {...}` | `aws_ssm_maintenance_window` |
| 4 | Session Manager | `enable_session_manager = true` | IAM policy + Session document |
| 5 | Custom Documents | `documents = {...}` | `aws_ssm_document` |
| 6 | AppConfig | `enable_appconfig = true` + `appconfig_environments = {...}` | `aws_appconfig_application` |
| 7 | State Manager | `associations = {...}` | `aws_ssm_association` |
| 8 | Resource Data Sync | `resource_data_syncs = {...}` | `aws_ssm_resource_data_sync` |
| 9 | Hybrid Activations | `create_activation = true` | `aws_ssm_activation` |

---

## Architecture Overview

```
+----------------------------------------------------------------------+
|                    AWS Systems Manager                               |
|                                                                      |
|  +---------------------+   +--------------------------------+        |
|  |  PARAMETER STORE    |   |  PATCH MANAGER                 |        |
|  |                     |   |                                |        |
|  |  /app/prod/db_host  |   |  Baseline: AL2023              |        |
|  |  /app/prod/secret   |   |  Baseline: Windows 2022        |        |
|  |  (SecureString+KMS) |   |  Patch Group: prod-linux       |        |
|  |  /common/region     |   |  Default baseline per OS       |        |
|  +---------------------+   +--------------------------------+        |
|                                                                      |
|  +---------------------+   +--------------------------------+        |
|  |  MAINTENANCE WINDOW |   |  SESSION MANAGER               |        |
|  |                     |   |                                |        |
|  |  cron(0 2 ? * SUN*) |   |  No SSH / No bastion needed    |        |
|  |  Duration: 4 hrs    |   |  IAM-controlled access         |        |
|  |  Task: Patch Install|   |  Logs -> S3 + CloudWatch       |        |
|  |  Target: tag filter |   |  KMS encrypted sessions        |        |
|  +---------------------+   +--------------------------------+        |
|                                                                      |
|  +---------------------+   +--------------------------------+        |
|  |  APPCONFIG          |   |  STATE MANAGER                 |        |
|  |                     |   |                                |        |
|  |  Application        |   |  Association: Install CW Agent |        |
|  |  Environments       |   |  Association: Gather Inventory |        |
|  |  Feature Flags      |   |  Schedule: rate(1 day)         |        |
|  |  Deployment strat   |   |  Target: All managed instances |        |
|  +---------------------+   +--------------------------------+        |
|                                                                      |
|  +---------------------+   +--------------------------------+        |
|  |  CUSTOM DOCUMENTS   |   |  HYBRID ACTIVATIONS            |        |
|  |                     |   |                                |        |
|  |  Run Command docs   |   |  On-premises servers           |        |
|  |  Automation docs    |   |  Activation ID + Code          |        |
|  |  Session docs       |   |  IAM role for hybrid           |        |
|  |  ChangeCalendar     |   |  Registration limit + expiry   |        |
|  +---------------------+   +--------------------------------+        |
|                                                                      |
|  +---------------------+                                            |
|  |  RESOURCE DATA SYNC |                                            |
|  |                     |                                            |
|  |  Inventory -> S3    |                                            |
|  |  JsonSerDe format   |                                            |
|  |  Athena/QuickSight  |                                            |
|  +---------------------+                                            |
+----------------------------------------------------------------------+
```

---

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage Examples

### Example 1 — Parameter Store only

```hcl
module "ssm" {
  source      = "../../tf-aws-ssm"
  name        = "myapp"
  environment = "prod"
  kms_key_arn = module.kms.key_arns["app"]

  parameters = {
    "/myapp/prod/db_host" = {
      value       = "db.prod.example.com"
      type        = "String"
      description = "RDS cluster endpoint"
    }
    "/myapp/prod/db_password" = {
      value       = "super-secret-password"
      type        = "SecureString"
      description = "RDS master password - encrypted with KMS"
      tier        = "Standard"
    }
    "/myapp/prod/allowed_regions" = {
      value = "us-east-1,eu-west-1"
      type  = "StringList"
    }
    "/myapp/prod/ami_id" = {
      value     = "ami-0abcdef1234567890"
      type      = "String"
      data_type = "aws:ec2:image"   # validates it's a real AMI
    }
  }
}

# Read parameter in another module:
# data "aws_ssm_parameter" "db_host" {
#   name = "/myapp/prod/db_host"
# }
```

---

### Example 2 — Patch Manager (AL2023 + Windows)

```hcl
module "ssm" {
  source      = "../../tf-aws-ssm"
  name        = "myapp"
  environment = "prod"

  create_patch_baselines = true

  patch_baselines = {
    "amazon-linux-2023" = {
      operating_system = "AMAZON_LINUX_2023"
      description      = "AL2023 - Security + Bugfix, auto-approve after 7 days"
      default_baseline = true
      approval_rules = [{
        approve_after_days  = 7
        compliance_level    = "HIGH"
        enable_non_security = false
        patch_filters = [
          { key = "CLASSIFICATION", values = ["SecurityUpdates", "Bugfix"] },
          { key = "SEVERITY",       values = ["Critical", "Important"] }
        ]
      }]
    }
    "windows-server-2022" = {
      operating_system = "WINDOWS"
      description      = "Windows - Critical + Security, approve after 14 days"
      default_baseline = true
      approval_rules = [{
        approve_after_days = 14
        compliance_level   = "CRITICAL"
        patch_filters = [
          { key = "CLASSIFICATION", values = ["CriticalUpdates", "SecurityUpdates"] },
          { key = "MSRC_SEVERITY",  values = ["Critical", "Important"] }
        ]
      }]
    }
  }

  patch_groups = {
    "prod-linux"   = "amazon-linux-2023"
    "prod-windows" = "windows-server-2022"
    "dev-linux"    = "amazon-linux-2023"
  }
}
# Tag EC2 instances with: "Patch Group" = "prod-linux"
```

---

### Example 3 — Maintenance Window (Sunday patching)

```hcl
module "ssm" {
  source      = "../../tf-aws-ssm"
  name        = "myapp"
  environment = "prod"

  maintenance_windows = {
    "sunday-patching" = {
      schedule          = "cron(0 2 ? * SUN *)"   # Every Sunday 02:00 UTC
      duration          = 4
      cutoff            = 1
      description       = "Weekly Sunday patching window -- prod Linux"
      schedule_timezone = "UTC"

      targets = [
        { key = "tag:Patch Group", values = ["prod-linux"] }
      ]

      tasks = {
        "install-patches" = {
          task_type       = "RUN_COMMAND"
          document_name   = "AWS-RunPatchBaseline"
          priority        = 1
          max_concurrency = "20%"
          max_errors      = "10%"
          parameters      = { Operation = ["Install"], RebootOption = ["RebootIfNeeded"] }
        }
      }
    }
  }
}
```

---

### Example 4 — Session Manager (no SSH bastion)

```hcl
module "ssm" {
  source      = "../../tf-aws-ssm"
  name        = "myapp"
  environment = "prod"
  kms_key_arn = module.kms.key_arns["app"]

  enable_session_manager               = true
  session_manager_s3_bucket            = module.s3.bucket_id
  session_manager_s3_prefix            = "session-logs/"
  session_manager_cloudwatch_log_group = "/aws/ssm/session-manager/myapp-prod"
  session_manager_log_retention_days   = 90
}

# Attach the output policy to your EC2 instance role:
# resource "aws_iam_role_policy_attachment" "ssm" {
#   role       = module.iam_role.role_name
#   policy_arn = module.ssm.session_manager_policy_arn
# }
# Then connect: aws ssm start-session --target i-0abc123def456
```

---

### Example 5 — Custom SSM Documents

```hcl
module "ssm" {
  source      = "../../tf-aws-ssm"
  name        = "myapp"
  environment = "prod"

  documents = {
    "restart-nginx" = {
      document_type   = "Command"
      document_format = "YAML"
      target_type     = "/AWS::EC2::Instance"
      content         = <<-YAML
        schemaVersion: "2.2"
        description: "Restart nginx gracefully"
        mainSteps:
          - action: aws:runShellScript
            name: restartNginx
            inputs:
              runCommand:
                - nginx -t && systemctl reload nginx || systemctl restart nginx
                - systemctl is-active nginx
      YAML
    }
    "collect-diagnostics" = {
      document_type   = "Automation"
      document_format = "YAML"
      content         = <<-YAML
        schemaVersion: "0.3"
        description: "Collect system diagnostics"
        mainSteps:
          - name: collectLogs
            action: aws:runCommand
            inputs:
              DocumentName: AWS-RunShellScript
              Parameters:
                commands:
                  - journalctl -u nginx --since "1 hour ago" > /tmp/nginx.log
                  - df -h >> /tmp/diag.txt
                  - free -m >> /tmp/diag.txt
      YAML
    }
  }
}
```

---

### Example 6 — AppConfig (feature flags)

```hcl
module "ssm" {
  source      = "../../tf-aws-ssm"
  name        = "myapp"
  environment = "prod"

  enable_appconfig           = true
  appconfig_application_name = "myapp-feature-flags"
  appconfig_description      = "Feature flag management for MyApp"

  appconfig_environments = {
    "prod" = {
      description = "Production environment"
      monitors    = []
    }
    "staging" = {
      description = "Staging environment"
      monitors    = []
    }
  }

  appconfig_configuration_profiles = {
    "feature-flags" = {
      type        = "AWS.AppConfig.FeatureFlags"
      description = "Feature flag configuration"
    }
    "app-config" = {
      type        = "AWS.Freeform"
      description = "General application settings"
      validators  = []
    }
  }

  appconfig_deployment_strategy = {
    name                           = "gradual-30min"
    deployment_duration_in_minutes = 30
    growth_factor                  = 10
    final_bake_time_in_minutes     = 10
    growth_type                    = "LINEAR"
  }
}
```

---

### Example 7 — State Manager (CloudWatch Agent + Inventory)

```hcl
module "ssm" {
  source      = "../../tf-aws-ssm"
  name        = "myapp"
  environment = "prod"

  associations = {
    "install-cloudwatch-agent" = {
      document_name       = "AWS-ConfigureAWSPackage"
      schedule            = "rate(30 days)"
      compliance_severity = "MEDIUM"
      targets             = [{ key = "tag:Environment", values = ["prod"] }]
      parameters = {
        action = ["Install"]
        name   = ["AmazonCloudWatchAgent"]
      }
    }
    "gather-inventory" = {
      document_name       = "AWS-GatherSoftwareInventory"
      schedule            = "rate(1 day)"
      compliance_severity = "LOW"
      targets             = [{ key = "InstanceIds", values = ["*"] }]
      parameters          = {}
    }
    "run-patch-scan" = {
      document_name       = "AWS-RunPatchBaseline"
      schedule            = "cron(0 8 ? * MON-FRI *)"
      compliance_severity = "HIGH"
      targets             = [{ key = "tag:Patch Group", values = ["prod-linux"] }]
      parameters          = { Operation = ["Scan"] }
    }
  }
}
```

---

### Example 8 — Resource Data Sync (inventory to S3)

```hcl
module "ssm" {
  source      = "../../tf-aws-ssm"
  name        = "myapp"
  environment = "prod"

  resource_data_syncs = {
    "inventory-to-s3" = {
      s3_bucket_name = "my-ssm-inventory-bucket"
      s3_region      = "us-east-1"
      s3_prefix      = "ssm-inventory/"
      sync_format    = "JsonSerDe"
    }
  }
}
# Query with Athena:
# SELECT resourceid, resourcetype, capturedtime
# FROM "ssm_inventory_db"."aws_instanceinformation"
# WHERE accountid = '123456789012'
```

---

### Example 9 — Hybrid Activation (on-premises server)

```hcl
module "ssm" {
  source      = "../../tf-aws-ssm"
  name        = "myapp"
  environment = "prod"

  create_activation             = true
  activation_description        = "Data center servers -- rack A"
  activation_registration_limit = 50
  activation_expiration_date    = "2026-12-31T23:59:59Z"
}

# After apply, register on-premises server:
# sudo amazon-ssm-agent -register \
#   -code <activation_code output> \
#   -id   <activation_id output>   \
#   -region us-east-1
# sudo systemctl start amazon-ssm-agent
```

---

### Example 10 — Full Stack (all 9 features together)

```hcl
module "ssm" {
  source      = "../../tf-aws-ssm"
  name        = "myapp"
  environment = "prod"
  kms_key_arn = module.kms.key_arns["app"]

  tags = {
    Team    = "platform"
    CostCenter = "engineering"
  }

  # ── Feature 1: Parameter Store ───────────────────────────────────────────────
  parameters = {
    "/myapp/prod/db_host" = {
      value       = "db.prod.example.com"
      type        = "String"
      description = "RDS cluster endpoint"
    }
    "/myapp/prod/db_password" = {
      value       = "change-me-at-runtime"
      type        = "SecureString"
      description = "RDS master password — KMS encrypted"
    }
    "/myapp/prod/feature_regions" = {
      value = "us-east-1,eu-west-1,ap-southeast-1"
      type  = "StringList"
    }
  }

  # ── Feature 2: Patch Manager ─────────────────────────────────────────────────
  create_patch_baselines = true

  patch_baselines = {
    "amazon-linux-2023" = {
      operating_system = "AMAZON_LINUX_2023"
      description      = "AL2023 security baseline — approve after 7 days"
      default_baseline = true
      approval_rules = [{
        approve_after_days  = 7
        compliance_level    = "HIGH"
        enable_non_security = false
        patch_filters = [
          { key = "CLASSIFICATION", values = ["SecurityUpdates", "Bugfix"] },
          { key = "SEVERITY",       values = ["Critical", "Important"] }
        ]
      }]
    }
    "windows-2022" = {
      operating_system = "WINDOWS"
      description      = "Windows Server 2022 — approve after 14 days"
      default_baseline = true
      approval_rules = [{
        approve_after_days = 14
        compliance_level   = "CRITICAL"
        patch_filters = [
          { key = "CLASSIFICATION", values = ["CriticalUpdates", "SecurityUpdates"] },
          { key = "MSRC_SEVERITY",  values = ["Critical", "Important"] }
        ]
      }]
    }
  }

  patch_groups = {
    "prod-linux"   = "amazon-linux-2023"
    "prod-windows" = "windows-2022"
    "dev-linux"    = "amazon-linux-2023"
  }

  # ── Feature 3: Maintenance Windows ──────────────────────────────────────────
  maintenance_windows = {
    "weekly-linux-patch" = {
      schedule          = "cron(0 2 ? * SUN *)"
      duration          = 4
      cutoff            = 1
      description       = "Weekly Sunday patching — prod Linux"
      schedule_timezone = "UTC"
      targets = [
        { key = "tag:Patch Group", values = ["prod-linux"] }
      ]
      tasks = {
        "patch-install" = {
          task_type       = "RUN_COMMAND"
          document_name   = "AWS-RunPatchBaseline"
          priority        = 1
          max_concurrency = "20%"
          max_errors      = "10%"
          parameters      = { Operation = ["Install"], RebootOption = ["RebootIfNeeded"] }
        }
      }
    }
  }

  # ── Feature 4: Session Manager ───────────────────────────────────────────────
  enable_session_manager               = true
  session_manager_s3_bucket            = "my-session-logs-bucket"
  session_manager_s3_prefix            = "session-logs/"
  session_manager_cloudwatch_log_group = "/aws/ssm/session-manager/myapp-prod"
  session_manager_log_retention_days   = 90

  # ── Feature 5: Custom Documents ─────────────────────────────────────────────
  documents = {
    "restart-app" = {
      document_type   = "Command"
      document_format = "YAML"
      target_type     = "/AWS::EC2::Instance"
      content         = <<-YAML
        schemaVersion: "2.2"
        description: "Restart application service"
        mainSteps:
          - action: aws:runShellScript
            name: restartApp
            inputs:
              runCommand:
                - systemctl restart myapp
                - systemctl is-active myapp
      YAML
    }
  }

  # ── Feature 6: AppConfig ────────────────────────────────────────────────────
  enable_appconfig           = true
  appconfig_application_name = "myapp-config"
  appconfig_description      = "Dynamic configuration for MyApp"

  appconfig_environments = {
    "prod" = {
      description = "Production"
      monitors    = []
    }
    "staging" = {
      description = "Staging"
      monitors    = []
    }
  }

  appconfig_configuration_profiles = {
    "feature-flags" = {
      type        = "AWS.AppConfig.FeatureFlags"
      description = "Feature toggles"
    }
    "runtime-config" = {
      type        = "AWS.Freeform"
      description = "Runtime application settings"
    }
  }

  appconfig_deployment_strategy = {
    name                           = "gradual-30min"
    deployment_duration_in_minutes = 30
    growth_factor                  = 10
    final_bake_time_in_minutes     = 10
    growth_type                    = "LINEAR"
    replicate_to                   = "NONE"
  }

  # ── Feature 7: State Manager ─────────────────────────────────────────────────
  associations = {
    "install-cw-agent" = {
      document_name       = "AWS-ConfigureAWSPackage"
      schedule            = "rate(30 days)"
      compliance_severity = "MEDIUM"
      targets             = [{ key = "tag:Environment", values = ["prod"] }]
      parameters          = { action = ["Install"], name = ["AmazonCloudWatchAgent"] }
    }
    "gather-inventory" = {
      document_name       = "AWS-GatherSoftwareInventory"
      schedule            = "rate(1 day)"
      compliance_severity = "LOW"
      targets             = [{ key = "InstanceIds", values = ["*"] }]
      parameters          = {}
    }
  }

  # ── Feature 8: Resource Data Sync ───────────────────────────────────────────
  resource_data_syncs = {
    "inventory-sync" = {
      s3_bucket_name = "my-ssm-inventory-bucket"
      s3_region      = "us-east-1"
      s3_prefix      = "ssm-inventory/myapp/"
      sync_format    = "JsonSerDe"
    }
  }

  # ── Feature 9: Hybrid Activation ─────────────────────────────────────────────
  create_activation             = true
  activation_description        = "On-premises servers — primary data center"
  activation_registration_limit = 25
  activation_expiration_date    = "2026-12-31T23:59:59Z"
}

# Outputs consumed by other modules
output "ssm_session_policy_arn" {
  value = module.ssm.session_manager_policy_arn
}

output "ssm_appconfig_app_id" {
  value = module.ssm.appconfig_application_id
}
```

---

## Tag-Based Patching Flow

```
EC2 Instance
  tag: "Patch Group" = "prod-linux"
       |
       v
SSM Patch Group "prod-linux"
       |
       v
Patch Baseline "amazon-linux-2023"
  Rule: SecurityUpdates SEVERITY=Critical,Important
  approve_after_days = 7
       |
       v
Maintenance Window "sunday-patching"
  cron(0 2 ? * SUN *)
       |
       v
Task: AWS-RunPatchBaseline
  Operation = Install
  RebootOption = RebootIfNeeded
```

---

## Session Manager vs SSH Comparison

| Aspect | SSH + Bastion | Session Manager |
|--------|---------------|-----------------|
| Port open | 22 inbound | None |
| Key management | SSH key files | IAM policy |
| Audit trail | Manual setup | Auto: CloudWatch + S3 |
| VPC requirement | Bastion in public subnet | VPC endpoint or NAT |
| Cost | EC2 bastion ~$0.02/hr | Free (SSM free tier) |
| MFA support | No | Yes (IAM MFA) |

---

## AppConfig Rollout Strategy

```
Deploy config change
       |
       v
 0%  -> 10% -> 20% -> ... -> 100%  (LINEAR, growth_factor=10)
       |
   Bake time: 10 min at 100%
       |
   CloudWatch alarms monitor for errors
       |
   If alarm fires -> auto rollback to previous config
```

---

## Inputs

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `name` | `string` | required | Base name used as prefix for all SSM resources. |
| `environment` | `string` | `"dev"` | Deployment environment (dev, staging, prod). |
| `tags` | `map(string)` | `{}` | Additional tags applied to all resources. |
| `kms_key_arn` | `string` | `null` | KMS key ARN for encrypting SecureString parameters, AppConfig, and Session Manager logs. |
| `parameters` | `map(object)` | `{}` | Map of SSM Parameter Store parameters. Key = full parameter path. Type: String, SecureString, or StringList. |
| `create_patch_baselines` | `bool` | `false` | Create SSM Patch Baselines for managed instance patching. |
| `patch_baselines` | `map(object)` | `{}` | Map of patch baselines. Supports WINDOWS, AMAZON_LINUX_2023, AMAZON_LINUX_2, UBUNTU, REDHAT_ENTERPRISE_LINUX, CENTOS, DEBIAN, SUSE. |
| `patch_groups` | `map(string)` | `{}` | Map of patch group name => patch_baselines map key. Associates EC2 instances by Patch Group tag. |
| `maintenance_windows` | `map(object)` | `{}` | Map of SSM Maintenance Windows for scheduled patching or automation tasks. |
| `enable_session_manager` | `bool` | `false` | Configure Session Manager: create IAM policy, preferences document, and optional logging. |
| `session_manager_s3_bucket` | `string` | `null` | S3 bucket for Session Manager session logs. Null to disable S3 logging. |
| `session_manager_s3_prefix` | `string` | `"ssm-session-logs/"` | S3 prefix for Session Manager session logs. |
| `session_manager_cloudwatch_log_group` | `string` | `null` | CloudWatch Log Group name for Session Manager. Null to disable CloudWatch logging. |
| `session_manager_log_retention_days` | `number` | `30` | Retention in days for Session Manager CloudWatch logs. |
| `documents` | `map(object)` | `{}` | Map of custom SSM Documents. document_type: Command, Automation, Session, Package, or ChangeCalendar. |
| `enable_appconfig` | `bool` | `false` | Create AppConfig application for dynamic configuration management. |
| `appconfig_application_name` | `string` | `null` | AppConfig application name. Defaults to var.name when null. |
| `appconfig_description` | `string` | `"Managed by Terraform"` | Description of the AppConfig application. |
| `appconfig_environments` | `map(object)` | `{}` | Map of AppConfig environments. Each can have CloudWatch alarm monitors. |
| `appconfig_configuration_profiles` | `map(object)` | `{}` | Map of AppConfig configuration profiles. type: AWS.Freeform or AWS.AppConfig.FeatureFlags. |
| `appconfig_deployment_strategy` | `object` | `{}` | AppConfig deployment strategy controlling duration, growth factor, and bake time. |
| `associations` | `map(object)` | `{}` | Map of SSM State Manager Associations — automatically apply SSM documents to targets on a schedule. |
| `resource_data_syncs` | `map(object)` | `{}` | Map of SSM Resource Data Syncs — export inventory data to S3 for Athena/QuickSight analysis. |
| `create_activation` | `bool` | `false` | Create SSM Activation for on-premises or hybrid servers. |
| `activation_description` | `string` | `"Hybrid server activation"` | Description of the SSM Activation. |
| `activation_registration_limit` | `number` | `10` | Max number of on-premises servers that can register with this activation. |
| `activation_expiration_date` | `string` | `null` | Expiration date (RFC3339). Null = 30 days from now. |
| `activation_iam_role_name` | `string` | `null` | IAM role name for hybrid activation. Auto-created when null. |

---

## Outputs

| Output | Description |
|--------|-------------|
| `parameter_arns` | Map of parameter path => ARN. |
| `parameter_names` | Map of parameter key => full SSM path. |
| `parameter_versions` | Map of parameter path => current version number. |
| `patch_baseline_ids` | Map of baseline key => baseline ID. |
| `patch_baseline_arns` | Map of baseline key => baseline ARN. |
| `maintenance_window_ids` | Map of window key => maintenance window ID. |
| `maintenance_window_role_arn` | ARN of the IAM role for maintenance window tasks. |
| `session_manager_policy_arn` | ARN of the IAM policy to attach to EC2 instance roles for Session Manager. |
| `session_manager_log_group_name` | CloudWatch Log Group name for Session Manager session logs. |
| `document_arns` | Map of document key => ARN. |
| `document_names` | Map of document key => SSM document name. |
| `appconfig_application_id` | AppConfig application ID. |
| `appconfig_application_arn` | AppConfig application ARN. |
| `appconfig_environment_ids` | Map of environment name => AppConfig environment ID. |
| `appconfig_configuration_profile_ids` | Map of profile name => configuration profile ID. |
| `appconfig_deployment_strategy_id` | AppConfig deployment strategy ID. |
| `association_ids` | Map of association key => association ID. |
| `resource_data_sync_names` | Map of sync key => resource data sync name. |
| `activation_id` | SSM Activation ID. Use with activation_code to register on-premises servers. |
| `activation_code` | Activation code for registering on-premises servers. Treat as sensitive. |
| `activation_role_arn` | IAM role ARN for hybrid activation. |

---

## Testing and Verification

```bash
# Verify parameter was created
aws ssm get-parameter --name "/myapp/prod/db_host"

# Verify patch baseline
aws ssm describe-patch-baselines --filters "Key=NAME_PREFIX,Values=myapp"

# Start Session Manager session (no SSH needed)
aws ssm start-session --target i-0abc123def456789

# List maintenance windows
aws ssm describe-maintenance-windows

# Check State Manager associations
aws ssm list-associations --association-filter-list key=AssociationName,value=myapp-prod

# List AppConfig applications
aws appconfig list-applications

# Verify hybrid activation
aws ssm describe-activations
```

---

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws | >= 5.0 |

---

## Notes

### Parameter Store — lifecycle ignore_changes

The `aws_ssm_parameter` resources include `lifecycle { ignore_changes = [value] }`. This means Terraform will create parameters on first apply but will not overwrite values changed outside Terraform (e.g., by application secrets rotation). To force a value update, use `terraform taint` or remove the lifecycle block temporarily.

### Session Manager SSM-SessionManagerRunShell document

The `SSM-SessionManagerRunShell` document is an AWS-reserved name that overrides the default Session Manager preferences for the entire account. If you already have this document in your account, importing it first is recommended:

```bash
terraform import module.ssm.aws_ssm_document.session_manager_prefs[0] SSM-SessionManagerRunShell
```

### Maintenance Window task targets

The task resource assumes at least one target exists at index `0` for each maintenance window that has tasks. Ensure `targets` is non-empty when `tasks` is non-empty.

### Patch baseline — default_baseline

Setting `default_baseline = true` creates an `aws_ssm_default_patch_baseline` resource that replaces the AWS-provided default for that operating system. Only one default baseline per OS is allowed per account. If multiple baselines for the same OS have `default_baseline = true`, the last one applied wins.

### AppConfig deployment strategy — replicate_to

Valid values for `replicate_to` are `NONE` and `SSM_DOCUMENT`. Use `SSM_DOCUMENT` only if you want AppConfig to replicate configuration data to SSM Parameter Store.

### Hybrid activation — expiration_date

If `activation_expiration_date` is `null`, AWS defaults the expiration to 24 hours from creation (not 30 days as the variable description suggests — plan accordingly and set an explicit date for long-lived activations).

