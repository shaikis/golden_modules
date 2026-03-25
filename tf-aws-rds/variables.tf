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
  default = {
} }

# ---------------------------------------------------------------------------
# Engine
# ---------------------------------------------------------------------------
variable "engine" {
  description = "Database engine: mysql, postgres, mariadb, oracle-ee, sqlserver-ee, etc."
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version. Leave empty to use latest."
  type        = string
  default     = "15.5"
}

variable "instance_class" {
  description = "DB instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "license_model" {
  description = "License model. Required for Oracle/SQL Server."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------
variable "db_name" {
  description = "Name of the initial database."
  type        = string
  default     = null
}

variable "username" {
  description = "Master username."
  type        = string
  default     = "dbadmin"
}

variable "password" {
  description = "Master password. Use manage_master_user_password=true to let AWS manage it."
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Let RDS manage the master password in Secrets Manager."
  type        = bool
  default     = true
}

variable "master_user_secret_kms_key_id" {
  description = "KMS key for master password secret (if manage_master_user_password=true)."
  type        = string
  default     = null
}

variable "port" {
  description = "Database port. Defaults to engine-specific port."
  type        = number
  default     = null
}

# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------
variable "allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Max storage for autoscaling (0 = disabled)."
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "gp2, gp3, io1."
  type        = string
  default     = "gp3"
}

variable "iops" {
  description = "IOPS for io1/io2/gp3."
  type        = number
  default     = null
}

variable "storage_encrypted" {
  description = "Encrypt the database storage."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for storage encryption."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
variable "db_subnet_group_name" {
  description = "DB subnet group name. Required."
  type        = string
}

variable "vpc_security_group_ids" {
  description = "Security group IDs to associate."
  type        = list(string)
  default     = []
}

variable "publicly_accessible" {
  description = "Allow public internet access."
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "AZ for single-AZ deployment."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# High Availability
# ---------------------------------------------------------------------------
variable "multi_az" {
  description = "Enable Multi-AZ deployment."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------
variable "backup_retention_period" {
  description = "Backup retention in days (0 = disabled)."
  type        = number
  default     = 14
}

variable "backup_window" {
  description = "Daily backup window (UTC). e.g. 03:00-04:00"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window. e.g. sun:05:00-sun:06:00"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy."
  type        = bool
  default     = false
}

variable "final_snapshot_identifier_prefix" {
  description = "Prefix for final snapshot identifier."
  type        = string
  default     = "final"
}

variable "copy_tags_to_snapshot" {
  description = "Copy tags to DB snapshots."
  type        = bool
  default     = true
}

variable "delete_automated_backups" {
  description = "Delete automated backups on destroy."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Protection
# ---------------------------------------------------------------------------
variable "deletion_protection" {
  description = "Prevent deletion of the DB instance."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Monitoring
# ---------------------------------------------------------------------------
variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 = disabled). Valid: 0,1,5,10,15,30,60."
  type        = number
  default     = 60
}

variable "monitoring_role_arn" {
  description = "ARN of IAM role for enhanced monitoring."
  type        = string
  default     = null
}

variable "create_monitoring_role" {
  description = "Auto-create IAM role for enhanced monitoring."
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights."
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention in days."
  type        = number
  default     = 7
}

variable "performance_insights_kms_key_id" {
  description = "KMS key for Performance Insights."
  type        = string
  default     = null
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch."
  type        = list(string)
  default     = ["postgresql"]
}

# ---------------------------------------------------------------------------
# Parameter / Option Groups
# ---------------------------------------------------------------------------
variable "parameter_group_name" {
  description = "Parameter group name. Leave empty to use default."
  type        = string
  default     = null
}

variable "option_group_name" {
  description = "Option group name. Mainly for MySQL/Oracle."
  type        = string
  default     = null
}

variable "parameters" {
  description = "Map of DB parameters to create a custom parameter group."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "create_parameter_group" {
  description = "Create a custom parameter group from the parameters list."
  type        = bool
  default     = false
}

variable "parameter_group_family" {
  description = "Parameter group family (e.g. postgres15)."
  type        = string
  default     = "postgres15"
}

# ---------------------------------------------------------------------------
# Read Replicas
# ---------------------------------------------------------------------------
variable "replicate_source_db" {
  description = "ARN of a source DB instance to create a read replica."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Cross-Region Automated Backup Replication (choice-based)
# ---------------------------------------------------------------------------
variable "enable_automated_backup_replication" {
  description = <<-EOT
    Enable automated backup replication to a secondary AWS region.
    When true, set automated_backup_replication_region and backup_retention_period >= 1.
    NOTE: The aws_db_instance_automated_backups_replication resource runs in the
    destination region. It is created directly in the cross_region example using
    provider = aws.dr alongside this module call.
  EOT
  type        = bool
  default     = false
}

variable "automated_backup_replication_region" {
  description = "Destination region for automated backup replication (e.g. 'us-west-2'). Used only in examples."
  type        = string
  default     = null
}

variable "automated_backup_replication_retention_period" {
  description = "Retention period (days) for replicated automated backups in the destination region."
  type        = number
  default     = 7
}

variable "automated_backup_replication_kms_key_arn" {
  description = "KMS key ARN in the destination region for encrypting replicated backups. Null = AWS-managed key."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Miscellaneous
# ---------------------------------------------------------------------------
variable "auto_minor_version_upgrade" {
  type    = bool
  default = true
}
variable "apply_immediately" {
  type    = bool
  default = false
}
variable "allow_major_version_upgrade" {
  type    = bool
  default = false
}
variable "ca_cert_identifier" {
  type    = string
  default = null
}
variable "character_set_name" {
  type    = string
  default = null
}
variable "timezone" {
  type    = string
  default = null
}
variable "network_type" {
  type    = string
  default = null
}
