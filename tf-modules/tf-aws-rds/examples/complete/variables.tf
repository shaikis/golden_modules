variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "platform-db"
}
variable "name_prefix" {
  type    = string
  default = "prod"
}
variable "environment" {
  type    = string
  default = "prod"
}
variable "project" {
  type    = string
  default = "platform"
}
variable "owner" {
  type    = string
  default = "data-team"
}
variable "cost_center" {
  type    = string
  default = "CC-400"
}
variable "tags" {
  type    = map(string)
  default = {
} }

variable "engine" {
  type    = string
  default = "postgres"
}
variable "engine_version" {
  type    = string
  default = "15.5"
}
variable "instance_class" {
  type    = string
  default = "db.r6g.large"
}

variable "db_name" {
  type    = string
  default = "platformdb"
}
variable "username" {
  type    = string
  default = "dbadmin"
}
variable "manage_master_user_password" {
  type    = bool
  default = true
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
variable "storage_encrypted" {
  type    = bool
  default = true
}

variable "multi_az" {
  type    = bool
  default = true
}
variable "db_subnet_group_name" {
  type    = string
  default = ""
}
variable "vpc_security_group_ids" {
  type    = list(string)
  default = []
}
variable "publicly_accessible" {
  type    = bool
  default = false
}

variable "backup_retention_period" {
  type    = number
  default = 30
}
variable "backup_window" {
  type    = string
  default = "02:00-03:00"
}
variable "maintenance_window" {
  type    = string
  default = "sun:04:00-sun:05:00"
}
variable "skip_final_snapshot" {
  type    = bool
  default = false
}
variable "deletion_protection" {
  type    = bool
  default = true
}

variable "monitoring_interval" {
  type    = number
  default = 60
}
variable "create_monitoring_role" {
  type    = bool
  default = true
}
variable "performance_insights_enabled" {
  type    = bool
  default = true
}
variable "performance_insights_retention_period" {
  type    = number
  default = 7
}

variable "enabled_cloudwatch_logs_exports" {
  type    = list(string)
  default = ["postgresql", "upgrade"]
}

variable "create_parameter_group" {
  type    = bool
  default = true
}
variable "parameter_group_family" {
  type    = string
  default = "postgres15"
}
variable "parameters" {
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = [
    { name = "log_connections",    value = "1" },
    { name = "log_disconnections", value = "1" },
    { name = "log_checkpoints",    value = "1" },
  ]
}
