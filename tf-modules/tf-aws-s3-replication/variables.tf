# ---------------------------------------------------------------------------
# Naming & Tagging
# ---------------------------------------------------------------------------
variable "source_bucket_name" {
  description = "Name of the source S3 bucket to create."
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
  default = {
} }

# ---------------------------------------------------------------------------
# Source bucket
# ---------------------------------------------------------------------------
variable "source_kms_key_id" {
  description = "KMS key ARN for source bucket encryption."
  type        = string
  default     = null
}

variable "source_region" {
  description = "AWS region for the source bucket."
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning on source bucket (required for replication)."
  type        = bool
  default     = true
}

variable "enable_mfa_delete" {
  type    = bool
  default = false
}

variable "source_lifecycle_rules" {
  description = "Lifecycle rules for the source bucket."
  type = list(object({
    id      = string
    enabled = optional(bool, true)
    expiration_days = optional(number, null)
    noncurrent_version_expiration_days = optional(number, 90)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
  }))
  default = []
}

variable "enable_access_logging" {
  type    = bool
  default = false
}

variable "access_log_bucket_id" {
  type    = string
  default = ""
}

# ---------------------------------------------------------------------------
# Same-Region Replication (SRR) — backup bucket in same region
# ---------------------------------------------------------------------------
variable "enable_srr" {
  description = "Create a same-region replica (backup) bucket."
  type        = bool
  default     = false
}

variable "srr_bucket_name" {
  description = "Name for the SRR destination bucket. Defaults to source-backup."
  type        = string
  default     = ""
}

variable "srr_kms_key_id" {
  description = "KMS key ARN for SRR destination bucket encryption."
  type        = string
  default     = null
}

variable "srr_storage_class" {
  description = "Storage class override for SRR replicated objects."
  type        = string
  default     = "STANDARD"
}

# ---------------------------------------------------------------------------
# Cross-Region Replication (CRR) — one or more destination regions
# ---------------------------------------------------------------------------
variable "enable_crr" {
  description = "Enable cross-region replication to one or more destination buckets."
  type        = bool
  default     = false
}

variable "crr_destinations" {
  description = "Map of CRR destinations. Key = rule name."
  type = map(object({
    bucket_arn         = string          # ARN of existing destination bucket
    region             = string
    kms_key_id         = optional(string, null)
    storage_class      = optional(string, "STANDARD")
    prefix_filter      = optional(string, null)
    delete_marker_replication = optional(bool, false)
    replica_ownership  = optional(string, "Destination")  # Destination or Source
    access_control_translation_owner = optional(string, null)  # Destination (if cross-account)
    account            = optional(string, null)           # Dest account ID (cross-account)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Replication IAM Role
# ---------------------------------------------------------------------------
variable "replication_role_arn" {
  description = "Existing IAM role ARN for replication. Leave empty to auto-create."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# AWS Backup integration
# ---------------------------------------------------------------------------
variable "enable_aws_backup" {
  description = "Create an AWS Backup plan for this S3 bucket."
  type        = bool
  default     = false
}

variable "backup_vault_name" {
  description = "AWS Backup vault name."
  type        = string
  default     = "Default"
}

variable "backup_schedule" {
  description = "CRON or rate expression for backup frequency."
  type        = string
  default     = "cron(0 2 * * ? *)"
}

variable "backup_retention_days" {
  description = "Days to retain backups."
  type        = number
  default     = 30
}

variable "backup_kms_key_arn" {
  description = "KMS key for AWS Backup vault encryption."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Object Lock (WORM backup)
# ---------------------------------------------------------------------------
variable "object_lock_enabled" {
  type    = bool
  default = false
}

variable "object_lock_mode" {
  type    = string
  default = "GOVERNANCE"
}

variable "object_lock_days" {
  type    = number
  default = null
}

variable "object_lock_years" {
  type    = number
  default = null
}

# ---------------------------------------------------------------------------
# Bucket policies
# ---------------------------------------------------------------------------
variable "attach_deny_insecure_transport" {
  type    = bool
  default = true
}

variable "attach_require_tls12" {
  type    = bool
  default = true
}
