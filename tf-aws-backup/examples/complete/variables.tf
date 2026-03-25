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

variable "iam_role_name" {
  type    = string
  default = null
}

variable "dr_vault_arn" {
  description = "DR vault ARN for cross-region copy"
  type        = string
  default     = null
}

variable "report_bucket" {
  description = "S3 bucket for backup reports"
  type        = string
  default     = null
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
