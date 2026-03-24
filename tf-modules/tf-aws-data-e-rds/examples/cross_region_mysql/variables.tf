variable "primary_region" {
  type    = string
  default = "us-east-1"
}
variable "dr_region" {
  type    = string
  default = "us-west-2"
}
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
  default = "myproject"
}
variable "owner" {
  type    = string
  default = "platform"
}
variable "cost_center" {
  type    = string
  default = "shared"
}
variable "tags" {
  type    = map(string)
  default = {
} }

# Engine
variable "engine_version" {
  type    = string
  default = "8.0"
}
variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}
variable "parameter_group_family" {
  type    = string
  default = "mysql8.0"
}

# Database
variable "db_name" {
  type    = string
  default = "appdb"
}
variable "username" {
  type    = string
  default = "admin"
}

# Storage
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

# Encryption
variable "primary_kms_key_arn" {
  type    = string
  default = null
}
variable "dr_kms_key_arn" {
  type    = string
  default = null
}

# Network — Primary
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

# Network — DR
variable "dr_subnet_group_name" {
  type    = string
  default = null
}
variable "dr_security_group_ids" {
  type    = list(string)
  default = []
}

# Backup
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

# Monitoring
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
  default = ["error", "general", "slowquery"]
}

# Parameter group
variable "create_parameter_group" {
  type    = bool
  default = false
}
variable "parameters" {
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

# Cross-region toggles
variable "enable_automated_backup_replication" {
  type    = bool
  default = false
}
variable "automated_backup_replication_retention_period" {
  type    = number
  default = 7
}
variable "automated_backup_replication_kms_key_arn" {
  type    = string
  default = null
}
variable "create_cross_region_replica" {
  type    = bool
  default = false
}
variable "replica_instance_class" {
  type    = string
  default = "db.t3.medium"
}
