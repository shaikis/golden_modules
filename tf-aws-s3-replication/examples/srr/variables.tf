variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "myapp-prod-data"
}
variable "environment" {
  type    = string
  default = "prod"
}
variable "project" {
  type    = string
  default = "myapp"
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
  default = {
} }

variable "source_bucket_name" {
  type    = string
  default = "myapp-prod-data"
}
variable "source_region" {
  type    = string
  default = "us-east-1"
}
variable "kms_name" {
  type    = string
  default = "s3-backup"
}

variable "enable_srr" {
  type    = bool
  default = true
}
variable "srr_bucket_name" {
  type    = string
  default = "myapp-prod-data-backup"
}
variable "srr_storage_class" {
  type    = string
  default = "STANDARD_IA"
}

variable "enable_aws_backup" {
  type    = bool
  default = true
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
      id = "transition-to-ia"
      transitions = [
        { days = 30; storage_class = "STANDARD_IA" },
        { days = 90; storage_class = "GLACIER" },
      ]
      noncurrent_version_expiration_days = 60
    }
  ]
}
