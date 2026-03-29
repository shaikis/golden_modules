variable "account_id" {
  description = "AWS account ID for the Storage Lens configuration. Defaults to the current caller account."
  type        = string
  default     = null
}

variable "config_id" {
  description = "Identifier for the Storage Lens configuration."
  type        = string
}

variable "enabled" {
  description = "Whether the Storage Lens configuration is enabled."
  type        = bool
  default     = true
}

variable "account_level" {
  description = "Account-level metrics configuration."
  type = object({
    activity_metrics                   = optional(bool, null)
    advanced_cost_optimization_metrics = optional(bool, null)
    advanced_data_protection_metrics   = optional(bool, null)
    detailed_status_code_metrics       = optional(bool, null)
    bucket_level = optional(object({
      activity_metrics                   = optional(bool, null)
      advanced_cost_optimization_metrics = optional(bool, null)
      advanced_data_protection_metrics   = optional(bool, null)
      detailed_status_code_metrics       = optional(bool, null)
      prefix_level = optional(object({
        storage_metrics = object({
          enabled = bool
          selection_criteria = optional(object({
            delimiter                    = optional(string, null)
            max_depth                    = optional(number, null)
            min_storage_bytes_percentage = optional(number, null)
          }), null)
        })
      }), null)
    }), {})
  })
  default = {}
}

variable "include" {
  description = "Optional include filter for buckets and regions."
  type = object({
    buckets = optional(set(string), [])
    regions = optional(set(string), [])
  })
  default = null
}

variable "exclude" {
  description = "Optional exclude filter for buckets and regions."
  type = object({
    buckets = optional(set(string), [])
    regions = optional(set(string), [])
  })
  default = null
}

variable "data_export" {
  description = "Optional Storage Lens export configuration."
  type = object({
    cloud_watch_metrics_enabled = optional(bool, null)
    s3_bucket_destination = optional(object({
      arn                   = string
      account_id            = optional(string, null)
      format                = optional(string, "CSV")
      output_schema_version = optional(string, "V_1")
      prefix                = optional(string, null)
      encryption = optional(object({
        type   = string
        key_id = optional(string, null)
      }), null)
    }), null)
  })
  default = null

  validation {
    condition = var.data_export == null || var.data_export.s3_bucket_destination == null || var.data_export.s3_bucket_destination.encryption == null || (
      contains(["SSE-S3", "SSE-KMS"], var.data_export.s3_bucket_destination.encryption.type) &&
      (
        var.data_export.s3_bucket_destination.encryption.type != "SSE-KMS" ||
        var.data_export.s3_bucket_destination.encryption.key_id != null
      )
    )
    error_message = "data_export.s3_bucket_destination.encryption.type must be SSE-S3 or SSE-KMS. key_id is required when encryption.type is SSE-KMS."
  }
}

variable "tags" {
  description = "Tags applied to the Storage Lens configuration."
  type        = map(string)
  default     = {}
}
