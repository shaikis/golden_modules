variable "name" {
  description = "Name of the DocumentDB cluster."
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

# ── Network ────────────────────────────────────────────────────────────────────
variable "vpc_id" {
  description = "VPC ID where the DocumentDB cluster will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the DocumentDB subnet group (minimum 2, in different AZs)."
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to DocumentDB port 27017."
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to DocumentDB."
  type        = list(string)
  default     = []
}

# ── Cluster ────────────────────────────────────────────────────────────────────
variable "engine_version" {
  description = "DocumentDB engine version."
  type        = string
  default     = "5.0.0"
}

variable "instance_class" {
  description = "Instance class for DocumentDB cluster members (e.g. db.r6g.large, db.r6g.xlarge)."
  type        = string
  default     = "db.r6g.large"
}

variable "cluster_size" {
  description = "Total number of instances: 1 primary + (cluster_size - 1) readers. Minimum 1."
  type        = number
  default     = 3
  validation {
    condition     = var.cluster_size >= 1 && var.cluster_size <= 16
    error_message = "cluster_size must be between 1 and 16."
  }
}

variable "master_username" {
  description = "Master username for the DocumentDB cluster."
  type        = string
  default     = "docdbadmin"
}

variable "master_password" {
  description = "Master password. Leave null to auto-generate a secure random password stored in Secrets Manager."
  type        = string
  default     = null
  sensitive   = true
}

variable "port" {
  description = "DocumentDB port."
  type        = number
  default     = 27017
}

# ── Backup & Maintenance ───────────────────────────────────────────────────────
variable "backup_retention_days" {
  description = "Number of days to retain automated backups (1–35)."
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 1 and 35."
  }
}

variable "preferred_backup_window" {
  description = "Daily time range for automated backups (UTC). Format: hh24:mi-hh24:mi."
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Weekly time range for maintenance (UTC). Format: ddd:hh24:mi-ddd:hh24:mi."
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on cluster deletion. Set false for production."
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Name of the final snapshot when skip_final_snapshot = false."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Enable deletion protection on the cluster. Prevents accidental deletion."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately or during next maintenance window."
  type        = bool
  default     = false
}

# ── Encryption & Security ──────────────────────────────────────────────────────
variable "storage_encrypted" {
  description = "Enable storage encryption at rest."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for storage encryption. Uses AWS-managed key when null."
  type        = string
  default     = null
}

variable "tls_enabled" {
  description = "Enable TLS for all DocumentDB connections."
  type        = bool
  default     = true
}

# ── Logs ───────────────────────────────────────────────────────────────────────
variable "enabled_cloudwatch_logs" {
  description = "Log types to export to CloudWatch: audit, profiler."
  type        = list(string)
  default     = ["audit"]
  validation {
    condition     = alltrue([for l in var.enabled_cloudwatch_logs : contains(["audit", "profiler"], l)])
    error_message = "Valid log types are audit and profiler."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 14
}

# ── Parameter Group ────────────────────────────────────────────────────────────
variable "cluster_parameters" {
  description = "Custom cluster parameter group parameters."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "pending-reboot")
  }))
  default = []
}
