# ── Common ─────────────────────────────────────────────────────────────────────
variable "name" {
  description = "Base name used as prefix for all SSM resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting SecureString parameters, AppConfig, and Session Manager logs."
  type        = string
  default     = null
}

# ── FEATURE 1: PARAMETER STORE ─────────────────────────────────────────────────
variable "parameters" {
  description = "Map of SSM Parameter Store parameters. Key = full parameter path (supports /hierarchy/path). Type: String | SecureString | StringList."
  type = map(object({
    value           = string
    type            = optional(string, "String")
    description     = optional(string, "")
    tier            = optional(string, "Standard")
    data_type       = optional(string, "text")
    overwrite       = optional(bool, true)
    allowed_pattern = optional(string, null)
  }))
  default = {}
}

# ── FEATURE 2: PATCH MANAGER ───────────────────────────────────────────────────
variable "create_patch_baselines" {
  description = "Create SSM Patch Baselines for managed instance patching."
  type        = bool
  default     = false
}

variable "patch_baselines" {
  description = "Map of patch baselines. Supports WINDOWS, AMAZON_LINUX_2023, AMAZON_LINUX_2, UBUNTU, REDHAT_ENTERPRISE_LINUX, CENTOS, DEBIAN, SUSE."
  type = map(object({
    operating_system = string
    description      = optional(string, "")
    approved_patches = optional(list(string), [])
    rejected_patches = optional(list(string), [])
    default_baseline = optional(bool, false)
    approval_rules = optional(list(object({
      approve_after_days  = optional(number, 7)
      compliance_level    = optional(string, "UNSPECIFIED")
      enable_non_security = optional(bool, false)
      patch_filters = list(object({
        key    = string
        values = list(string)
      }))
    })), [])
    global_filters = optional(list(object({
      key    = string
      values = list(string)
    })), [])
  }))
  default = {}
}

variable "patch_groups" {
  description = "Map of patch group name => patch_baselines map key. Associates EC2 instances (by 'Patch Group' tag) to a baseline."
  type        = map(string)
  default     = {}
}

# ── FEATURE 3: MAINTENANCE WINDOWS ────────────────────────────────────────────
variable "maintenance_windows" {
  description = "Map of SSM Maintenance Windows for scheduled patching or automation tasks."
  type = map(object({
    schedule          = string
    duration          = number
    cutoff            = number
    description       = optional(string, "")
    enabled           = optional(bool, true)
    schedule_timezone = optional(string, "UTC")
    allow_unassociated_targets = optional(bool, false)
    targets = optional(list(object({
      key    = string
      values = list(string)
    })), [])
    tasks = optional(map(object({
      task_type        = string
      document_name    = string
      document_version = optional(string, null)
      priority         = optional(number, 1)
      max_concurrency  = optional(string, "50%")
      max_errors       = optional(string, "10%")
      service_role_arn = optional(string, null)
      parameters       = optional(map(list(string)), {})
    })), {})
  }))
  default = {}
}

# ── FEATURE 4: SESSION MANAGER ────────────────────────────────────────────────
variable "enable_session_manager" {
  description = "Configure Session Manager: create IAM policy, preferences document, and optional logging."
  type        = bool
  default     = false
}

variable "session_manager_s3_bucket" {
  description = "S3 bucket for Session Manager session logs. Null to disable S3 logging."
  type        = string
  default     = null
}

variable "session_manager_s3_prefix" {
  description = "S3 prefix for Session Manager session logs."
  type        = string
  default     = "ssm-session-logs/"
}

variable "session_manager_cloudwatch_log_group" {
  description = "CloudWatch Log Group name for Session Manager. Null to disable CloudWatch logging."
  type        = string
  default     = null
}

variable "session_manager_log_retention_days" {
  description = "Retention in days for Session Manager CloudWatch logs."
  type        = number
  default     = 30
}

# ── FEATURE 5: SSM DOCUMENTS ──────────────────────────────────────────────────
variable "documents" {
  description = "Map of custom SSM Documents. document_type: Command | Automation | Session | Package | ChangeCalendar."
  type = map(object({
    document_type   = string
    document_format = optional(string, "YAML")
    content         = string
    target_type     = optional(string, null)
    permissions     = optional(map(list(string)), {})
  }))
  default = {}
}

# ── FEATURE 6: APPCONFIG ──────────────────────────────────────────────────────
variable "enable_appconfig" {
  description = "Create AppConfig application for dynamic configuration management."
  type        = bool
  default     = false
}

variable "appconfig_application_name" {
  description = "AppConfig application name. Defaults to var.name when null."
  type        = string
  default     = null
}

variable "appconfig_description" {
  description = "Description of the AppConfig application."
  type        = string
  default     = "Managed by Terraform"
}

variable "appconfig_environments" {
  description = "Map of AppConfig environments (dev, staging, prod). Each can have CloudWatch alarm monitors."
  type = map(object({
    description = optional(string, "")
    monitors = optional(list(object({
      alarm_arn      = string
      alarm_role_arn = optional(string, null)
    })), [])
  }))
  default = {}
}

variable "appconfig_configuration_profiles" {
  description = "Map of AppConfig configuration profiles. type: AWS.Freeform | AWS.AppConfig.FeatureFlags."
  type = map(object({
    location_uri       = optional(string, "hosted")
    type               = optional(string, "AWS.Freeform")
    description        = optional(string, "")
    retrieval_role_arn = optional(string, null)
    validators = optional(list(object({
      type    = string
      content = string
    })), [])
  }))
  default = {}
}

variable "appconfig_deployment_strategy" {
  description = "AppConfig deployment strategy. Controls how config changes roll out (duration, growth factor, bake time)."
  type = object({
    name                           = optional(string, "terraform-managed")
    deployment_duration_in_minutes = optional(number, 30)
    growth_factor                  = optional(number, 10)
    final_bake_time_in_minutes     = optional(number, 10)
    growth_type                    = optional(string, "LINEAR")
    replicate_to                   = optional(string, "NONE")
    description                    = optional(string, "Managed by Terraform")
  })
  default = {}
}

# ── FEATURE 7: STATE MANAGER ASSOCIATIONS ─────────────────────────────────────
variable "associations" {
  description = "Map of SSM State Manager Associations — automatically apply SSM documents to targets on a schedule."
  type = map(object({
    document_name    = string
    document_version = optional(string, null)
    schedule         = optional(string, null)
    targets = optional(list(object({
      key    = string
      values = list(string)
    })), [])
    parameters          = optional(map(list(string)), {})
    compliance_severity = optional(string, "UNSPECIFIED")
    max_concurrency     = optional(string, null)
    max_errors          = optional(string, null)
    apply_only_at_cron_interval = optional(bool, false)
    output_location = optional(object({
      s3_bucket_name = string
      s3_key_prefix  = optional(string, "")
      s3_region      = optional(string, null)
    }), null)
  }))
  default = {}
}

# ── FEATURE 8: RESOURCE DATA SYNC ─────────────────────────────────────────────
variable "resource_data_syncs" {
  description = "Map of SSM Resource Data Syncs — export inventory data to S3 for Athena/QuickSight analysis."
  type = map(object({
    s3_bucket_name = string
    s3_region      = string
    s3_prefix      = optional(string, "")
    sync_format    = optional(string, "JsonSerDe")
    kms_key_arn    = optional(string, null)
  }))
  default = {}
}

# ── FEATURE 9: HYBRID ACTIVATIONS ─────────────────────────────────────────────
variable "create_activation" {
  description = "Create SSM Activation for on-premises or hybrid servers."
  type        = bool
  default     = false
}

variable "activation_description" {
  description = "Description of the SSM Activation."
  type        = string
  default     = "Hybrid server activation"
}

variable "activation_registration_limit" {
  description = "Max number of on-premises servers that can register with this activation."
  type        = number
  default     = 10
}

variable "activation_expiration_date" {
  description = "Expiration date (RFC3339). Null = 30 days from now."
  type        = string
  default     = null
}

variable "activation_iam_role_name" {
  description = "IAM role name for hybrid activation. Auto-created when null."
  type        = string
  default     = null
}
