variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "data-encryption"
}
variable "name_prefix" {
  type    = string
  default = "myapp"
}
variable "environment" {
  type    = string
  default = "prod"
}
variable "project" {
  type    = string
  default = "fintech-platform"
}
variable "owner" {
  type    = string
  default = "security-team"
}
variable "cost_center" {
  type    = string
  default = "CC-1234"
}
variable "tags" {
  type    = map(string)
  default = {
} }

variable "description" {
  type    = string
  default = "Encrypts application data and secrets in production"
}
variable "key_usage" {
  type    = string
  default = "ENCRYPT_DECRYPT"
}
variable "customer_master_key_spec" {
  type    = string
  default = "SYMMETRIC_DEFAULT"
}
variable "enable_key_rotation" {
  type    = bool
  default = true
}
variable "deletion_window_in_days" {
  type    = number
  default = 30
}
variable "multi_region" {
  type    = bool
  default = true
}

variable "kms_admin_role_name" {
  type    = string
  default = "KMSAdminRole"
}
variable "app_server_role_name" {
  type    = string
  default = "AppServerRole"
}
variable "lambda_exec_role_name" {
  type    = string
  default = "LambdaExecRole"
}
variable "autoscaling_role_path" {
  type    = string
  default = "aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
}

variable "aliases" {
  type    = list(string)
  default = ["prod/app-data", "prod/secrets"]
}
