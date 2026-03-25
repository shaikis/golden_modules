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

# SQL Server edition — choose one:
#   sqlserver-ee  : Enterprise Edition (BYOL or LI)
#   sqlserver-se  : Standard Edition (BYOL or LI)
#   sqlserver-ex  : Express Edition (free, max 1 vCPU / 1 GiB RAM)
#   sqlserver-web : Web Edition (LI only)
variable "sqlserver_edition" {
  type    = string
  default = "sqlserver-se"
}
variable "engine_version" {
  type    = string
  default = "15.00"
}     # SQL Server 2019
variable "instance_class" {
  type    = string
  default = "db.m5.xlarge"
}   # min for SE/EE

# License model:
#   license-included      : AWS provides the SQL Server license
#   bring-your-own-license : use your own SA/Volume License (EE and SE only)
variable "license_model" {
  type    = string
  default = "license-included"
}
variable "timezone" {
  type    = string
  default = "UTC"
}
variable "parameter_group_family" {
  type    = string
  default = "sqlserver-se-15.0"
}

variable "username" {
  type    = string
  default = "admin"
}

variable "allocated_storage" {
  type    = number
  default = 200
}   # min 200 GiB for SQL Server
variable "max_allocated_storage" {
  type    = number
  default = 1000
}
variable "storage_type" {
  type    = string
  default = "gp3"
}
variable "iops" {
  type    = number
  default = null
}

variable "primary_kms_key_arn" {
  type    = string
  default = null
}
variable "dr_kms_key_arn" {
  type    = string
  default = null
}

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
  default = ["agent", "error"]
}

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

# NOTE: SQL Server does NOT support cross-region read replicas.
# Only automated backup replication is available.
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
