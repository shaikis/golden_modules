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
  type = map(string)
  default = {
  }
}

# ────────────────────────────────────────────────────────────────────────────
# IAM
# ────────────────────────────────────────────────────────────────────────────
variable "create_iam_role" {
  description = "Create an IAM role for restore operations. Set false to provide iam_role_arn."
  type        = bool
  default     = true
}

variable "iam_role_arn" {
  description = "Existing IAM role ARN when create_iam_role = false."
  type        = string
  default     = null
}

variable "enable_s3_restore" {
  description = "Attach S3 restore managed policy to the IAM role."
  type        = bool
  default     = false
}

variable "enable_ec2_restore" {
  description = "Attach EC2 restore managed policy to the IAM role."
  type        = bool
  default     = true
}

variable "enable_rds_restore" {
  description = "Attach RDS restore permissions to the IAM role."
  type        = bool
  default     = true
}

variable "enable_dynamodb_restore" {
  description = "Attach DynamoDB restore permissions to the IAM role."
  type        = bool
  default     = false
}

variable "enable_ebs_restore" {
  description = "Attach EBS restore permissions to the IAM role."
  type        = bool
  default     = false
}

variable "enable_redshift_restore" {
  description = "Attach Redshift restore permissions to the IAM role."
  type        = bool
  default     = false
}

variable "enable_efs_restore" {
  description = "Attach EFS restore permissions to the IAM role."
  type        = bool
  default     = false
}

variable "enable_fsx_restore" {
  description = "Attach FSx restore permissions to the IAM role."
  type        = bool
  default     = false
}

variable "rds_resource_arns" {
  description = "RDS DB instance, cluster, or snapshot ARNs allowed for restore operations."
  type        = list(string)
  default     = []
}

variable "dynamodb_resource_arns" {
  description = "DynamoDB table or backup ARNs allowed for restore operations."
  type        = list(string)
  default     = []
}

variable "ebs_resource_arns" {
  description = "EBS volume or snapshot ARNs allowed for restore operations."
  type        = list(string)
  default     = []
}

variable "efs_resource_arns" {
  description = "EFS file system ARNs allowed for restore operations."
  type        = list(string)
  default     = []
}

variable "fsx_resource_arns" {
  description = "FSx file system or backup ARNs allowed for restore operations."
  type        = list(string)
  default     = []
}

variable "redshift_resource_arns" {
  description = "Redshift cluster or snapshot ARNs allowed for restore operations."
  type        = list(string)
  default     = []
}

variable "kms_key_arns" {
  description = "KMS key ARNs allowed for decrypt and grant operations during restore."
  type        = list(string)
  default     = []
}

variable "pass_role_arns" {
  description = "IAM role ARNs that AWS Backup may pass during restore workflows."
  type        = list(string)
  default     = []
}

# ────────────────────────────────────────────────────────────────────────────
# Restore Testing Plans
# ────────────────────────────────────────────────────────────────────────────
variable "restore_testing_plans" {
  description = <<-EOT
    Map of AWS Backup restore testing plans.
    Each plan defines a schedule to automatically test restores from backup vaults.

    algorithm:
      LATEST_WITHIN_WINDOW  - use the most recent recovery point within the window
      RANDOM_WITHIN_WINDOW  - use a random recovery point within the window

    recovery_point_types:
      SNAPSHOT   - standard backup snapshots
      CONTINUOUS - PITR continuous backup recovery points

    schedule_expression: cron() or rate() expression for automated test runs
    start_window_hours: hours after scheduled time before test is abandoned
  EOT
  type = map(object({
    # Recovery point selection
    algorithm             = optional(string, "LATEST_WITHIN_WINDOW")
    recovery_point_types  = optional(list(string), ["SNAPSHOT"])
    include_vaults        = optional(list(string), ["*"]) # vault ARNs or "*" for all
    exclude_vaults        = optional(list(string), [])
    selection_window_days = optional(number, 7) # days to look back for recovery points

    # Schedule
    schedule_expression          = optional(string, "cron(0 6 ? * SUN *)") # weekly
    schedule_expression_timezone = optional(string, "UTC")
    start_window_hours           = optional(number, 2)

    tags = optional(map(string), {})
  }))
  default = {}
}

# ────────────────────────────────────────────────────────────────────────────
# Restore Testing Selections
# ────────────────────────────────────────────────────────────────────────────
variable "restore_testing_selections" {
  description = <<-EOT
    Map of restore testing selections. Each selection defines which resources
    are included in a restore testing plan and how they should be restored.

    protected_resource_type: EC2 | EBS | RDS | Aurora | DynamoDB | EFS | S3 | FSx | Redshift | VirtualMachine

    restore_metadata_overrides: Override restore parameters per resource type.
    Examples:
      EC2: { availabilityZone = "us-east-1a", instanceType = "t3.micro" }
      RDS: { DBInstanceIdentifier = "test-restore-db", AvailabilityZone = "us-east-1a" }
      EFS: { newFileSystem = "true", CreationToken = "test-restore" }
      DynamoDB: { targetTableName = "test-restore-table" }
      S3: { newBucket = "test-restore-bucket", SSEAlgorithm = "AES256" }

    validation_window_hours: hours to wait after restore before validating success
  EOT
  type = map(object({
    restore_testing_plan_key = string # references restore_testing_plans key
    protected_resource_type  = string # EC2 | EBS | RDS | Aurora | DynamoDB | EFS | S3 | FSx

    # Target specific resources (optional - if empty, selects from all in vault)
    protected_resource_arns = optional(list(string), [])

    # Tag-based conditions to filter resources
    protected_resource_conditions = optional(object({
      string_equals = optional(list(object({
        key   = string
        value = string
      })), [])
      string_not_equals = optional(list(object({
        key   = string
        value = string
      })), [])
    }), null)

    # Override restore configuration
    restore_metadata_overrides = optional(map(string), {})

    # Validation
    validation_window_hours = optional(number, 4)

    iam_role_arn = optional(string, null) # null = use module-managed role
  }))
  default = {}
}

# ────────────────────────────────────────────────────────────────────────────
# SNS Notifications for Restore Events
# ────────────────────────────────────────────────────────────────────────────
variable "create_sns_topic" {
  description = "Create an SNS topic for restore event notifications."
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "Existing SNS topic ARN for restore notifications. Used when create_sns_topic = false."
  type        = string
  default     = null
}

variable "sns_kms_key_id" {
  description = "KMS key ID/ARN for SNS topic encryption. Only used when create_sns_topic = true."
  type        = string
  default     = null
}

# ────────────────────────────────────────────────────────────────────────────
# CloudWatch Alarms for Restore Failures
# ────────────────────────────────────────────────────────────────────────────
variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for failed/expired restore jobs."
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "SNS topic ARNs to notify when CloudWatch alarms fire."
  type        = list(string)
  default     = []
}

variable "restore_job_failed_threshold" {
  description = "CloudWatch alarm threshold: number of failed restore jobs before alarm fires."
  type        = number
  default     = 1
}

variable "restore_job_evaluation_periods" {
  description = "Number of CloudWatch metric evaluation periods."
  type        = number
  default     = 1
}

variable "restore_job_period" {
  description = "CloudWatch metric period in seconds."
  type        = number
  default     = 86400 # 24 hours
}

# ────────────────────────────────────────────────────────────────────────────
# CloudWatch Logs
# ────────────────────────────────────────────────────────────────────────────
variable "enable_cloudwatch_logs" {
  description = <<-EOT
    Enable CloudWatch Logs for all AWS Backup restore events.
    Creates a CloudWatch Log Group and an EventBridge rule that captures
    Restore Job State Change events and routes them to the log group.
    Also captures restore testing events when restore_testing_plans are configured.
  EOT
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain restore event logs in CloudWatch. 0 = never expire."
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

variable "create_cloudwatch_dashboard" {
  description = "Create a CloudWatch dashboard with restore job metrics and recent events."
  type        = bool
  default     = false
}

variable "dashboard_name" {
  description = "Name override for the CloudWatch dashboard. Defaults to <prefix>-restore-dashboard."
  type        = string
  default     = null
}
