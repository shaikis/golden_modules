# ────────────────────────────────────────────────────────────────────────────
# Naming & Tagging
# ────────────────────────────────────────────────────────────────────────────
variable "name" {
  type = string
}

variable "name_prefix" {
  type    = string
  default = ""
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = ""
}

variable "owner" {
  type    = string
  default = ""
}

variable "cost_center" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ────────────────────────────────────────────────────────────────────────────
# IAM
# ────────────────────────────────────────────────────────────────────────────
variable "create_iam_role" {
  description = "Create a dedicated IAM role for AWS Backup. Set false to provide iam_role_arn."
  type        = bool
  default     = true
}

variable "iam_role_arn" {
  description = "Pre-existing IAM role ARN. Used when create_iam_role = false."
  type        = string
  default     = null
}

variable "enable_s3_backup" {
  description = "Attach S3 backup/restore managed policies to the IAM role."
  type        = bool
  default     = false
}

variable "iam_role_name" {
  description = "Optional custom IAM role name. If not provided, module generates one."
  type        = string
  default     = null
}

# ────────────────────────────────────────────────────────────────────────────
# SNS (Module-Level Notifications)
# ────────────────────────────────────────────────────────────────────────────
variable "create_sns_topic" {
  description = <<-EOT
    Create a module-level SNS topic for backup event notifications.
    This topic is automatically attached to ALL vaults (unless a vault has its own sns_topic_arn).

    Behavior:
      create_sns_topic = true  + sns_topic_arn = null → module creates new SNS topic (auto-create)
      create_sns_topic = false + sns_topic_arn = ARN  → use existing topic (BYO from SNS module)
      create_sns_topic = false + sns_topic_arn = null → no module-level notifications
  EOT
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "Existing SNS topic ARN for backup notifications. When provided, create_sns_topic is ignored and no new topic is created (BYO pattern)."
  type        = string
  default     = null
}

variable "sns_kms_key_id" {
  description = "KMS key ID or ARN for SNS topic at-rest encryption. Only used when create_sns_topic = true and sns_topic_arn = null."
  type        = string
  default     = null
}

# ────────────────────────────────────────────────────────────────────────────
# Backup Vaults
# ────────────────────────────────────────────────────────────────────────────
variable "vaults" {
  description = <<-EOT
    Map of backup vaults to create. Key is appended to the vault name: <prefix>-<key>.
    Vault Lock:
      enable_vault_lock = true enables WORM protection.
      vault_lock_changeable_for_days = null → Compliance mode (immediately immutable).
      vault_lock_changeable_for_days = N    → Governance mode (admin can delete within N days).
  EOT
  type = map(object({
    kms_key_arn   = optional(string, null)
    force_destroy = optional(bool, false)
    policy        = optional(string, null) # JSON resource-based vault policy

    # Vault Lock (WORM)
    enable_vault_lock              = optional(bool, false)
    vault_lock_changeable_for_days = optional(number, null) # null = compliance mode
    vault_lock_max_retention_days  = optional(number, null)
    vault_lock_min_retention_days  = optional(number, null)

    # SNS Notifications
    sns_topic_arn = optional(string, null)
    notification_events = optional(list(string), [
      "BACKUP_JOB_STARTED",
      "BACKUP_JOB_COMPLETED",
      "BACKUP_JOB_FAILED",
      "RESTORE_JOB_STARTED",
      "RESTORE_JOB_COMPLETED",
      "COPY_JOB_STARTED",
      "COPY_JOB_SUCCESSFUL",
      "COPY_JOB_FAILED",
    ])

    tags = optional(map(string), {})
  }))
  default = {}
}

# ────────────────────────────────────────────────────────────────────────────
# Backup Plans
# ────────────────────────────────────────────────────────────────────────────
variable "plans" {
  description = <<-EOT
    Map of AWS Backup plans. Each plan contains one or more rules.

    Per rule:
      vault_key         → references a key in var.vaults (vault managed by this module)
      target_vault_name → explicit vault name (external / cross-account vaults)
      One of vault_key or target_vault_name must be set.

    PITR (Point-In-Time Recovery):
      enable_continuous_backup = true enables PITR for supported resources (RDS, Aurora, S3).
      When PITR is enabled: schedule can be null, delete_after must be ≤ 35 days,
      cold_storage_after must be null.

    Retention examples:
      Daily 35d  : lifecycle = { delete_after = 35 }
      Weekly 35d : lifecycle = { delete_after = 35 }
      Monthly 3m : lifecycle = { delete_after = 90 }
      Monthly 6m : lifecycle = { cold_storage_after = 30, delete_after = 180 }
      Monthly 2y : lifecycle = { cold_storage_after = 30, delete_after = 730 }
  EOT
  type = map(object({
    rules = list(object({
      rule_name                    = string
      vault_key                    = optional(string, null) # references var.vaults key
      target_vault_name            = optional(string, null) # explicit vault name
      schedule                     = optional(string, null) # null = on-demand / continuous
      schedule_expression_timezone = optional(string, "UTC")
      start_window                 = optional(number, 60)  # minutes before job must start
      completion_window            = optional(number, 180) # minutes to complete after start
      enable_continuous_backup     = optional(bool, false) # PITR
      recovery_point_tags          = optional(map(string), {})

      lifecycle = optional(object({
        cold_storage_after                        = optional(number, null) # days; null = no cold storage
        delete_after                              = number                 # days
        opt_in_to_archive_for_supported_resources = optional(bool, false)
      }), null)

      copy_actions = optional(list(object({
        destination_vault_arn = string
        lifecycle = optional(object({
          cold_storage_after = optional(number, null)
          delete_after       = number
        }), null)
      })), [])
    }))

    advanced_backup_settings = optional(list(object({
      resource_type  = string      # e.g. "EC2"
      backup_options = map(string) # e.g. { WindowsVSS = "enabled" }
    })), [])

    tags = optional(map(string), {})
  }))
  default = {}
}

# ────────────────────────────────────────────────────────────────────────────
# Backup Selections (Resource Assignments)
# ────────────────────────────────────────────────────────────────────────────
variable "selections" {
  description = <<-EOT
    Map of backup resource selections assigning resources to plans.
    Three selection methods (can be combined):
      resources      → ARN-based (specific resources or wildcard patterns)
      selection_tags → Tag-based (any resource with matching tags)
      conditions     → Attribute-based (fine-grained resource filtering)
  EOT
  type = map(object({
    plan_key     = string                 # references var.plans key
    iam_role_arn = optional(string, null) # null = use module-created role

    resources     = optional(list(string), []) # resource ARNs or arn:aws:*:*:*:* patterns
    not_resources = optional(list(string), []) # excluded ARNs

    # Tag-based selection
    selection_tags = optional(list(object({
      type  = string # STRINGEQUALS | STRINGLIKE | STRINGNOTEQUALS | STRINGNOTLIKE
      key   = string
      value = string
    })), [])

    # Attribute-based (IAM-style) conditions
    conditions = optional(object({
      string_equals = optional(list(object({
        key   = string # e.g. "aws:ResourceTag/Environment"
        value = string
      })), [])
      string_not_equals = optional(list(object({
        key   = string
        value = string
      })), [])
      string_like = optional(list(object({
        key   = string
        value = string
      })), [])
      string_not_like = optional(list(object({
        key   = string
        value = string
      })), [])
    }), null)
  }))
  default = {}
}

# ────────────────────────────────────────────────────────────────────────────
# Backup Framework (Compliance Audit)
# ────────────────────────────────────────────────────────────────────────────
variable "create_framework" {
  description = "Create an AWS Backup Audit Manager Framework for compliance controls."
  type        = bool
  default     = false
}

variable "framework_description" {
  type    = string
  default = "AWS Backup compliance framework"
}

variable "framework_controls" {
  description = <<-EOT
    Compliance controls for the Backup Audit Framework.
    Common control names:
      BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK
      BACKUP_RECOVERY_POINT_ENCRYPTED
      BACKUP_RECOVERY_POINT_MANUAL_DELETION_DISABLED
      BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN
      BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK
      BACKUP_LAST_RECOVERY_POINT_CREATED
      BACKUP_RESOURCES_PROTECTED_BY_CROSS_REGION
      BACKUP_RESOURCES_PROTECTED_BY_CROSS_ACCOUNT
  EOT
  type = list(object({
    name = string
    input_parameters = optional(list(object({
      name  = string
      value = string
    })), [])
    scope = optional(object({
      compliance_resource_ids   = optional(list(string), [])
      compliance_resource_types = optional(list(string), [])
      tags = optional(list(object({
        key   = string
        value = string
      })), [])
    }), null)
  }))
  default = []
}

# ────────────────────────────────────────────────────────────────────────────
# Report Plans
# ────────────────────────────────────────────────────────────────────────────
variable "report_plans" {
  description = <<-EOT
    Map of AWS Backup report plans delivered to an S3 bucket.
    report_template options:
      BACKUP_JOB_REPORT        – summary of backup jobs
      COPY_JOB_REPORT          – summary of copy jobs
      RESTORE_JOB_REPORT       – summary of restore jobs
      RESOURCE_COMPLIANCE_REPORT  – per-resource compliance against framework
      CONTROL_COMPLIANCE_REPORT   – per-control compliance status
  EOT
  type = map(object({
    description    = optional(string, "")
    formats        = optional(list(string), ["CSV", "JSON"])
    s3_bucket_name = string
    s3_key_prefix  = optional(string, null)

    report_template    = string
    framework_arns     = optional(list(string), [])
    accounts           = optional(list(string), [])
    regions            = optional(list(string), [])
    organization_units = optional(list(string), [])

    tags = optional(map(string), {})
  }))
  default = {}
}

# ────────────────────────────────────────────────────────────────────────────
# Account-Level Settings
# NOTE: Only ONE module instance per account should set these to true.
# ────────────────────────────────────────────────────────────────────────────
variable "configure_global_settings" {
  description = "Manage AWS Backup global settings (one per account). Controls cross-account backup."
  type        = bool
  default     = false
}

variable "enable_cross_account_backup" {
  description = "Allow cross-account backup copies. Requires AWS Organizations integration."
  type        = bool
  default     = false
}

variable "configure_region_settings" {
  description = "Manage region-level resource opt-in preferences (one per account per region)."
  type        = bool
  default     = false
}

variable "resource_type_opt_in_preference" {
  description = <<-EOT
    Map of resource type → bool for AWS Backup opt-in.
    Supported types: Aurora, CloudFormation, DynamoDB, EBS, EC2, EFS, FSx,
                     Neptune, RDS, Redshift, S3, SAP HANA on Amazon EC2,
                     Storage Gateway, Timestream, VirtualMachine
  EOT
  type        = map(bool)
  default     = {}
}

variable "resource_type_management_preference" {
  description = "Advanced management preferences. Supported: DynamoDB (advanced features), EFS (Intelligent-Tiering)."
  type        = map(bool)
  default     = {}
}

# ────────────────────────────────────────────────────────────────────────────
# CloudWatch Logs
# ────────────────────────────────────────────────────────────────────────────
variable "enable_cloudwatch_logs" {
  description = <<-EOT
    Enable CloudWatch Logs for all AWS Backup events.
    Creates a CloudWatch Log Group and an EventBridge rule that captures
    all aws.backup events (backup jobs, copy jobs, restore jobs, recovery points)
    and routes them to the log group.
  EOT
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain backup event logs in CloudWatch. 0 = never expire."
  type        = number
  default     = 90
  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch retention period value."
  }
}

variable "log_kms_key_arn" {
  description = "KMS key ARN for CloudWatch Log Group encryption at rest."
  type        = string
  default     = null
}

variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch metric alarms for failed backup jobs (requires enable_cloudwatch_logs = true for log-based alarms, or uses native AWS/Backup metrics)."
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "List of SNS topic ARNs to notify when CloudWatch alarms fire."
  type        = list(string)
  default     = []
}

variable "backup_job_failed_threshold" {
  description = "CloudWatch alarm threshold: number of failed backup jobs in the evaluation period before alarm fires."
  type        = number
  default     = 1
}

variable "copy_job_failed_threshold" {
  description = "CloudWatch alarm threshold: number of failed copy jobs before alarm fires."
  type        = number
  default     = 1
}

variable "create_cloudwatch_dashboard" {
  description = "Create a CloudWatch dashboard with backup and restore metrics overview."
  type        = bool
  default     = false
}

variable "dashboard_name" {
  description = "Name override for the CloudWatch dashboard. Defaults to <prefix>-backup-dashboard."
  type        = string
  default     = null
}
