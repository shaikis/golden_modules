# ---------------------------------------------------------------------------
# Naming & Tagging
# ---------------------------------------------------------------------------
variable "bucket_name" {
  description = "Base bucket name. Must be globally unique."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix prepended to bucket_name."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
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
  description = "Additional tags."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Bucket
# ---------------------------------------------------------------------------
variable "force_destroy" {
  description = "Allow Terraform to destroy bucket even when it contains objects."
  type        = bool
  default     = false
}

variable "object_ownership" {
  description = "Object ownership: BucketOwnerEnforced, BucketOwnerPreferred, or ObjectWriter."
  type        = string
  default     = "BucketOwnerEnforced"
}

# ---------------------------------------------------------------------------
# Versioning
# ---------------------------------------------------------------------------
variable "versioning_enabled" {
  description = "Enable S3 versioning."
  type        = bool
  default     = true
}

variable "mfa_delete" {
  description = "Enable MFA delete (requires versioning)."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Encryption
# ---------------------------------------------------------------------------
variable "sse_algorithm" {
  description = "Server-side encryption algorithm: aws:kms or AES256."
  type        = string
  default     = "aws:kms"

  validation {
    condition     = contains(["aws:kms", "AES256", "aws:kms:dsse"], var.sse_algorithm)
    error_message = "sse_algorithm must be aws:kms, AES256, or aws:kms:dsse."
  }
}

variable "kms_master_key_id" {
  description = "ARN of a customer-managed KMS key. Leave empty to use the AWS-managed key."
  type        = string
  default     = null
}

variable "bucket_key_enabled" {
  description = "Enable S3 Bucket Key to reduce KMS API calls cost."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Public Access Block
# ---------------------------------------------------------------------------
variable "block_public_acls" {
  description = "Block public ACLs."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies."
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs."
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Access Logging
# ---------------------------------------------------------------------------
variable "enable_access_logging" {
  description = "Enable S3 server access logging."
  type        = bool
  default     = false
}

variable "access_log_bucket" {
  description = "Destination bucket for access logs."
  type        = string
  default     = ""
}

variable "access_log_prefix" {
  description = "Prefix for access log objects."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Lifecycle Rules
# ---------------------------------------------------------------------------
variable "lifecycle_rules" {
  description = "List of lifecycle rules."
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
  default = []
}

# ---------------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------------
variable "cors_rules" {
  description = "List of CORS rules."
  type = list(object({
    allowed_headers = optional(list(string), [])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, null)
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Static Website
# ---------------------------------------------------------------------------
variable "website" {
  description = "Static website configuration."
  type = object({
    index_document           = optional(string, null)
    error_document           = optional(string, null)
    redirect_all_requests_to = optional(string, null)
  })
  default = null
}

# ---------------------------------------------------------------------------
# Bucket Policy
# ---------------------------------------------------------------------------
variable "bucket_policy" {
  description = "JSON bucket policy document."
  type        = string
  default     = ""
}

variable "attach_deny_insecure_transport_policy" {
  description = "Deny non-TLS (HTTP) requests to the bucket."
  type        = bool
  default     = true
}

variable "attach_require_latest_tls_policy" {
  description = "Require TLS 1.2+ for all requests."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Object Lock
# ---------------------------------------------------------------------------
variable "object_lock_enabled" {
  description = "Enable S3 Object Lock (requires versioning)."
  type        = bool
  default     = false
}

variable "object_lock_mode" {
  description = "Default retention mode: COMPLIANCE or GOVERNANCE."
  type        = string
  default     = "GOVERNANCE"
}

variable "object_lock_days" {
  description = "Default retention period in days (mutually exclusive with years)."
  type        = number
  default     = null
}

variable "object_lock_years" {
  description = "Default retention period in years."
  type        = number
  default     = null
}

# ---------------------------------------------------------------------------
# Replication
# ---------------------------------------------------------------------------
variable "replication_configuration" {
  description = "Cross-region or cross-account replication configuration."
  type = object({
    role = string
    rules = list(object({
      id                        = string
      status                    = optional(string, "Enabled")
      prefix                    = optional(string, null)
      destination_bucket        = string
      destination_storage_class = optional(string, "STANDARD")
      replica_kms_key_id        = optional(string, null)
      delete_marker_replication = optional(bool, false)
    }))
  })
  default = null
}

# ---------------------------------------------------------------------------
# Notifications
# ---------------------------------------------------------------------------
variable "notifications" {
  description = "S3 bucket notification configuration."
  type = object({
    lambda_functions = optional(list(object({
      lambda_function_arn = string
      events              = list(string)
      filter_prefix       = optional(string, null)
      filter_suffix       = optional(string, null)
    })), [])
    sqs_queues = optional(list(object({
      queue_arn     = string
      events        = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
    })), [])
    sns_topics = optional(list(object({
      topic_arn     = string
      events        = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
    })), [])
  })
  default = null
}

# ---------------------------------------------------------------------------
# Intelligent-Tiering
# ---------------------------------------------------------------------------
variable "intelligent_tiering_configurations" {
  description = "Intelligent-Tiering archive configurations."
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
  default = []
}
