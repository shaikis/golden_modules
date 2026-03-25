variable "primary_region" {
  type    = string
  default = "us-east-1"
}
variable "dr_west_region" {
  type    = string
  default = "us-west-2"
}
variable "dr_eu_region" {
  type    = string
  default = "eu-west-1"
}

variable "name" {
  type    = string
  default = "platform-prod-data"
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
  default = "CC-200"
}
variable "tags" {
  type    = map(string)
  default = {
} }

variable "source_bucket_name" {
  type    = string
  default = "platform-prod-data"
}
variable "source_region" {
  type    = string
  default = "us-east-1"
}

variable "dr_west_bucket_name" {
  type    = string
  default = "platform-prod-data-dr-us-west-2"
}
variable "dr_eu_bucket_name" {
  type    = string
  default = "platform-prod-data-dr-eu-west-1"
}

variable "enable_srr" {
  type    = bool
  default = true
}
variable "srr_bucket_name" {
  type    = string
  default = "platform-prod-data-srr-backup"
}
variable "srr_storage_class" {
  type    = string
  default = "STANDARD_IA"
}

variable "enable_crr" {
  type    = bool
  default = true
}

variable "enable_aws_backup" {
  type    = bool
  default = true
}
variable "backup_vault_name" {
  type    = string
  default = "platform-prod-vault"
}
variable "backup_schedule" {
  type    = string
  default = "cron(0 1 * * ? *)"
}
variable "backup_retention_days" {
  type    = number
  default = 90
}

variable "source_lifecycle_rules" {
  type = list(object({
    id      = string
    enabled = optional(bool, true)
    expiration_days = optional(number, null)
    noncurrent_version_expiration_days = optional(number, 90)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
  }))
  default = [
    {
      id = "standard-lifecycle"
      transitions = [
        { days = 30;  storage_class = "STANDARD_IA" },
        { days = 90;  storage_class = "GLACIER" },
        { days = 365; storage_class = "DEEP_ARCHIVE" },
      ]
      noncurrent_version_expiration_days = 90
    }
  ]
}
