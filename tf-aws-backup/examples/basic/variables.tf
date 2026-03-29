variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "myapp"
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
  default = {}
}

variable "create_iam_role" {
  type    = bool
  default = true
}
variable "iam_role_arn" {
  type    = string
  default = null
}
variable "enable_s3_backup" {
  type    = bool
  default = false
}

variable "vault_kms_key_arn" {
  type    = string
  default = null
}
variable "vault_force_destroy" {
  type    = bool
  default = false
}
variable "vault_sns_topic_arn" {
  type    = string
  default = null
}

variable "daily_retention_days" {
  type    = number
  default = 35
}
variable "cross_region_vault_arn" {
  type    = string
  default = null
}

variable "backup_tag_key" {
  type    = string
  default = "Backup"
}
variable "backup_tag_value" {
  type    = string
  default = "true"
}

variable "create_sns_topic" {
  type    = bool
  default = false
}
variable "sns_topic_arn" {
  type    = string
  default = null
}
variable "sns_kms_key_id" {
  type    = string
  default = null
}

variable "enable_cloudwatch_logs" {
  type    = bool
  default = false
}
variable "log_retention_days" {
  type    = number
  default = 90
}
variable "log_kms_key_arn" {
  type    = string
  default = null
}
variable "create_cloudwatch_alarms" {
  type    = bool
  default = false
}
variable "alarm_actions" {
  type    = list(string)
  default = []
}
variable "backup_job_failed_threshold" {
  type    = number
  default = 1
}
variable "copy_job_failed_threshold" {
  type    = number
  default = 1
}
variable "create_cloudwatch_dashboard" {
  type    = bool
  default = false
}
variable "dashboard_name" {
  type    = string
  default = null
}
