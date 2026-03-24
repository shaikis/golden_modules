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

# Oracle edition — choose one:
#   oracle-ee        : Enterprise Edition (BYOL or LI)
#   oracle-ee-cdb    : Enterprise Edition Container DB
#   oracle-se2       : Standard Edition 2 (BYOL or LI, max 16 vCPUs)
#   oracle-se2-cdb   : Standard Edition 2 Container DB
variable "oracle_edition" {
  type    = string
  default = "oracle-ee"
}
variable "engine_version" {
  type    = string
  default = "19.0.0.0.ru-2024-01.rur-2024-01.r1"
}
variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}

# License model:
#   bring-your-own-license : you own the Oracle license
#   license-included       : AWS provides the license (higher cost)
variable "license_model" {
  type    = string
  default = "bring-your-own-license"
}
variable "character_set_name" {
  type    = string
  default = "AL32UTF8"
}
variable "parameter_group_family" {
  type    = string
  default = "oracle-ee-19"
}

variable "username" {
  type    = string
  default = "admin"
}

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

variable "dr_subnet_group_name" {
  type    = string
  default = null
}
variable "dr_security_group_ids" {
  type    = list(string)
  default = []
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
  default = ["alert", "audit", "listener", "trace"]
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
