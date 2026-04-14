variable "aws_region" {
  type = string
}

variable "name" {
  type    = string
  default = "sqlserver-dev"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = "golden-modules"
}

variable "owner" {
  type    = string
  default = "platform"
}

variable "cost_center" {
  type    = string
  default = "engineering"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "instance_class" {
  type    = string
  default = "db.m6i.large"
}

variable "timezone" {
  type    = string
  default = "UTC"
}

variable "username" {
  type    = string
  default = "dbadmin"
}

variable "allocated_storage" {
  type    = number
  default = 200
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

variable "kms_key_arn" {
  type = string
}

variable "db_subnet_group_name" {
  type = string
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "backup_window" {
  type    = string
  default = "03:00-04:00"
}

variable "maintenance_window" {
  type    = string
  default = "sun:05:00-sun:06:00"
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "final_snapshot_identifier_prefix" {
  type    = string
  default = "final"
}

variable "deletion_protection" {
  type    = bool
  default = false
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
  default = ["error", "agent"]
}

variable "create_parameter_group" {
  type    = bool
  default = false
}

variable "parameter_group_family" {
  type    = string
  default = "sqlserver-dev-ee-16.0"
}

variable "parameters" {
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "sqlserver_developer_custom_engine_version_name" {
  type = string
}

variable "sqlserver_developer_media_bucket_name" {
  type = string
}

variable "sqlserver_developer_media_bucket_prefix" {
  type    = string
  default = null
}

variable "sqlserver_developer_media_files" {
  type = list(string)
}

variable "sqlserver_developer_custom_engine_version_description" {
  type    = string
  default = "SQL Server Developer Edition custom engine version managed by Terraform"
}
