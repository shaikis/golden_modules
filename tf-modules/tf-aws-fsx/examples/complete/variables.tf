variable "aws_region" {
  type    = string
  default = "us-east-1"
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

variable "windows" {
  type    = any
  default = null
}
variable "lustre" {
  type    = any
  default = null
}
variable "ontap" {
  type    = any
  default = null
}
variable "openzfs" {
  type    = any
  default = null
}

# AWS Backup toggles (choice-based)
variable "enable_ontap_backup" {
  type    = bool
  default = false
}
variable "ontap_backup_vault_name" {
  type    = string
  default = null
}
variable "ontap_backup_schedule" {
  type    = string
  default = "cron(0 2 * * ? *)"
}
variable "ontap_backup_retention_days" {
  type    = number
  default = 7
}
variable "enable_ontap_cross_region_backup" {
  type    = bool
  default = false
}
variable "ontap_cross_region_backup_vault_arn" {
  type    = string
  default = null
}
variable "ontap_cross_region_backup_kms_key_arn" {
  type    = string
  default = null
}
variable "ontap_cross_region_backup_retention_days" {
  type    = number
  default = 30
}
