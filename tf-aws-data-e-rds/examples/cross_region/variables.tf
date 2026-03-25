# ---------------------------------------------------------------------------
# Region
# ---------------------------------------------------------------------------
variable "primary_region" {
  type    = string
  default = "us-east-1"
}
variable "dr_region" {
  type    = string
  default = "us-west-2"
}

# ---------------------------------------------------------------------------
# Identity
# ---------------------------------------------------------------------------
variable "name" {
  type    = string
  default = "myapp"
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
# Engine
# ---------------------------------------------------------------------------
variable "engine" {
  type    = string
  default = "mysql"
}
variable "engine_version" {
  type    = string
  default = "8.0"
}
variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------
variable "db_name" {
  type    = string
  default = null
}
variable "username" {
  type    = string
  default = "admin"
}
variable "port" {
  type    = number
  default = 3306
}

# Credentials
variable "manage_master_user_password" {
  type    = bool
  default = true
}
variable "master_user_secret_kms_key_id" {
  type    = string
  default = null
}

# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------
variable "allocated_storage" {
  type    = number
  default = 100
}
variable "max_allocated_storage" {
  type    = number
  default = 500
}
variable "storage_type" {
  type    = string
  default = "gp3"
}
variable "iops" {
  type    = number
  default = null
}

# ---------------------------------------------------------------------------
# Encryption
# ---------------------------------------------------------------------------
variable "primary_kms_key_arn" {
  type    = string
  default = null
}
variable "dr_kms_key_arn" {
  type    = string
  default = null
}

# ---------------------------------------------------------------------------
# Network — Primary
# ---------------------------------------------------------------------------
variable "primary_subnet_group_name" {
  type    = string
  default = ""
}
variable "primary_security_group_ids" {
  type    = list(string)
  default = []
}
variable "multi_az" {
  type    = bool
  default = true
}

# ---------------------------------------------------------------------------
# Network — DR (used for replica)
# ---------------------------------------------------------------------------
variable "dr_subnet_group_name" {
  type    = string
  default = null
}
variable "dr_security_group_ids" {
  type    = list(string)
  default = []
}

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------
variable "backup_retention_period" {
  type    = number
  default = 7
}
variable "backup_window" {
  type    = string
  default = "02:00-03:00"
}
variable "maintenance_window" {
  type    = string
  default = "Mon:03:00-Mon:04:00"
}
variable "skip_final_snapshot" {
  type    = bool
  default = false
}
variable "final_snapshot_identifier_prefix" {
  type    = string
  default = "final"
}
variable "deletion_protection" {
  type    = bool
  default = true
}

# ---------------------------------------------------------------------------
# Monitoring
# ---------------------------------------------------------------------------
variable "monitoring_interval" {
  type    = number
  default = 60
}
variable "performance_insights_enabled" {
  type    = bool
  default = true
}
variable "enabled_cloudwatch_logs_exports" {
  type    = list(string)
  default = ["error", "slowquery"]
}

# ---------------------------------------------------------------------------
# Parameter Group
# ---------------------------------------------------------------------------
variable "create_parameter_group" {
  type    = bool
  default = false
}
variable "parameter_group_family" {
  type    = string
  default = "mysql8.0"
}
variable "parameters" {
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Cross-Region Feature Toggles (choice-based)
# ---------------------------------------------------------------------------
variable "enable_automated_backup_replication" {
  description = "Copy automated backups to the DR region (pattern 1)"
  type        = bool
  default     = false
}

variable "automated_backup_replication_retention_period" {
  description = "Days to retain automated backups in the DR region"
  type        = number
  default     = 7
}

variable "automated_backup_replication_kms_key_arn" {
  description = "KMS key in DR region for encrypting replicated backups. Null = AWS-managed."
  type        = string
  default     = null
}

variable "create_cross_region_replica" {
  description = "Create a live read replica in the DR region (pattern 2)"
  type        = bool
  default     = false
}

variable "replica_instance_class" {
  description = "Instance class for the DR read replica (can be smaller than primary)"
  type        = string
  default     = "db.t3.medium"
}
