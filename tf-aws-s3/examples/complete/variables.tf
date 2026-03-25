variable "aws_region" {
  type    = string
  default = "us-east-1"
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
  default = "infra-team"
}
variable "cost_center" {
  type    = string
  default = "CC-200"
}
variable "tags" {
  type    = map(string)
  default = {
} }

# KMS variables
variable "kms_name" {
  type    = string
  default = "s3-app-data"
}
variable "kms_name_prefix" {
  type    = string
  default = ""
}

# Log bucket variables
variable "log_bucket_name" {
  type    = string
  default = "company-prod-access-logs"
}
variable "log_bucket_owner" {
  type    = string
  default = "infra"
}
variable "log_sse_algorithm" {
  type    = string
  default = "AES256"
}

# Main bucket variables
variable "bucket_name" {
  type    = string
  default = "company-prod-app-data"
}
variable "name_prefix" {
  type    = string
  default = "company"
}
variable "force_destroy" {
  type    = bool
  default = false
}
variable "object_ownership" {
  type    = string
  default = "BucketOwnerEnforced"
}
variable "versioning_enabled" {
  type    = bool
  default = true
}
variable "mfa_delete" {
  type    = bool
  default = false
}
variable "sse_algorithm" {
  type    = string
  default = "aws:kms"
}
variable "bucket_key_enabled" {
  type    = bool
  default = true
}

variable "block_public_acls" {
  type    = bool
  default = true
}
variable "block_public_policy" {
  type    = bool
  default = true
}
variable "ignore_public_acls" {
  type    = bool
  default = true
}
variable "restrict_public_buckets" {
  type    = bool
  default = true
}

variable "enable_access_logging" {
  type    = bool
  default = true
}
variable "access_log_prefix" {
  type    = string
  default = "app-data/"
}

variable "attach_deny_insecure_transport_policy" {
  type    = bool
  default = true
}
variable "attach_require_latest_tls_policy" {
  type    = bool
  default = true
}

variable "lifecycle_rules" {
  type = list(object({
    id      = string
    enabled = optional(bool, true)
    prefix  = optional(string, null)
    tags    = optional(map(string), {})
    expiration = optional(object({
      days                         = optional(number, null)
      date                         = optional(string, null)
      expired_object_delete_marker = optional(bool, false)
    }), null)
    noncurrent_version_expiration = optional(object({
      noncurrent_days           = number
      newer_noncurrent_versions = optional(number, null)
    }), null)
    transition = optional(list(object({
      days          = optional(number, null)
      date          = optional(string, null)
      storage_class = string
    })), [])
    noncurrent_version_transition = optional(list(object({
      noncurrent_days           = number
      newer_noncurrent_versions = optional(number, null)
      storage_class             = string
    })), [])
  }))
  default = [
    {
      id      = "transition-to-ia"
      enabled = true
      transition = [
        { days = 30,  storage_class = "STANDARD_IA" },
        { days = 90,  storage_class = "GLACIER" },
        { days = 365, storage_class = "DEEP_ARCHIVE" },
      ]
      noncurrent_version_expiration = {
        noncurrent_days           = 90
        newer_noncurrent_versions = 3
      }
    }
  ]
}

variable "intelligent_tiering_configurations" {
  type = list(object({
    name   = string
    status = optional(string, "Enabled")
    filter = optional(object({
      prefix = optional(string, null)
      tags   = optional(map(string), {})
    }), null)
    tierings = list(object({
      access_tier = string
      days        = number
    }))
  }))
  default = [
    {
      name = "entire-bucket"
      tierings = [
        { access_tier = "ARCHIVE_ACCESS",      days = 90 },
        { access_tier = "DEEP_ARCHIVE_ACCESS", days = 180 },
      ]
    }
  ]
}
