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

# When iam_role_arn is set, create_iam_role is automatically treated as false
# When sns_topic_arn is set, create_sns_topic is automatically treated as false
variable "create_iam_role" {
  type    = bool
  default = true
}   # auto-create by default
variable "iam_role_arn" {
  type    = string
  default = null
}
variable "enable_s3_restore" {
  type    = bool
  default = false
}
variable "enable_ec2_restore" {
  type    = bool
  default = true
}
variable "enable_rds_restore" {
  type    = bool
  default = true
}
variable "enable_dynamodb_restore" {
  type    = bool
  default = false
}
variable "enable_ebs_restore" {
  type    = bool
  default = false
}
variable "enable_efs_restore" {
  type    = bool
  default = false
}
variable "enable_fsx_restore" {
  type    = bool
  default = false
}
variable "enable_redshift_restore" {
  type    = bool
  default = false
}

variable "rds_resource_arns" {
  type    = list(string)
  default = []
}
variable "dynamodb_resource_arns" {
  type    = list(string)
  default = []
}
variable "ebs_resource_arns" {
  type    = list(string)
  default = []
}
variable "efs_resource_arns" {
  type    = list(string)
  default = []
}
variable "fsx_resource_arns" {
  type    = list(string)
  default = []
}
variable "redshift_resource_arns" {
  type    = list(string)
  default = []
}
variable "kms_key_arns" {
  type    = list(string)
  default = []
}
variable "pass_role_arns" {
  type    = list(string)
  default = []
}

variable "create_sns_topic" {
  type    = bool
  default = false
}  # opt-in
variable "sns_topic_arn" {
  type    = string
  default = null
}
variable "sns_kms_key_id" {
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
variable "restore_job_failed_threshold" {
  type    = number
  default = 1
}
variable "restore_job_evaluation_periods" {
  type    = number
  default = 1
}
variable "restore_job_period" {
  type    = number
  default = 86400
}

variable "enable_restore_testing" {
  type    = bool
  default = false
}
variable "backup_vault_arns" {
  type    = list(string)
  default = ["*"]
}
variable "restore_test_instance_type" {
  type    = string
  default = "t3.micro"
}
variable "restore_test_az" {
  type    = string
  default = "us-east-1a"
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
variable "create_cloudwatch_dashboard" {
  type    = bool
  default = false
}
variable "dashboard_name" {
  type    = string
  default = null
}
