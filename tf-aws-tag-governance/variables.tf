variable "name" {
  description = "Base name for tag governance resources."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix for resource names."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment tag value."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to module-managed resources."
  type        = map(string)
  default     = {}
}

variable "required_tags" {
  description = <<-EOT
    Required tags to enforce with the AWS Config managed rule `REQUIRED_TAGS`.
    Up to 6 tags are supported by the AWS managed rule.

    Example:
      required_tags = {
        Backup = { value = "true" }
        BackupPolicy = { value = "daily" }
        Environment = { value = "prod" }
      }
  EOT
  type = map(object({
    value = optional(string, null)
  }))
  default = {}

  validation {
    condition     = length(var.required_tags) > 0 && length(var.required_tags) <= 6
    error_message = "required_tags must contain between 1 and 6 entries."
  }
}

variable "resource_types_scope" {
  description = "Optional AWS Config resource types to scope the required tag rule."
  type        = list(string)
  default     = []
}

variable "tag_rule_maximum_execution_frequency" {
  description = "Optional evaluation frequency for the required tags rule."
  type        = string
  default     = null

  validation {
    condition = contains([
      "__NULL__",
      "One_Hour",
      "Three_Hours",
      "Six_Hours",
      "Twelve_Hours",
      "TwentyFour_Hours"
    ], coalesce(var.tag_rule_maximum_execution_frequency, "__NULL__"))
    error_message = "tag_rule_maximum_execution_frequency must be null or a valid AWS Config execution frequency."
  }
}

variable "create_sns_topic" {
  description = "Create an SNS topic for compliance notifications."
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "Existing SNS topic ARN for compliance notifications."
  type        = string
  default     = null
}

variable "sns_kms_key_id" {
  description = "KMS key for the created SNS topic."
  type        = string
  default     = null
}

variable "create_eventbridge_notifications" {
  description = "Create an EventBridge rule to send AWS Config compliance changes to SNS."
  type        = bool
  default     = true
}

variable "create_config_recorder" {
  description = "Create the AWS Config recorder and delivery channel."
  type        = bool
  default     = false
}

variable "create_config_role" {
  description = "Create the IAM role for AWS Config when create_config_recorder is enabled."
  type        = bool
  default     = true
}

variable "config_role_arn" {
  description = "Existing IAM role ARN for AWS Config. Used when create_config_role is false."
  type        = string
  default     = null
}

variable "config_s3_bucket_name" {
  description = "S3 bucket name for AWS Config delivery channel snapshots and history."
  type        = string
  default     = null
}

variable "config_snapshot_delivery_frequency" {
  description = "Snapshot delivery frequency for the AWS Config delivery channel."
  type        = string
  default     = "TwentyFour_Hours"

  validation {
    condition = contains([
      "One_Hour",
      "Three_Hours",
      "Six_Hours",
      "Twelve_Hours",
      "TwentyFour_Hours"
    ], var.config_snapshot_delivery_frequency)
    error_message = "config_snapshot_delivery_frequency must be a valid AWS Config delivery frequency."
  }
}

variable "include_global_resource_types" {
  description = "Include global resource types in the AWS Config recorder."
  type        = bool
  default     = true
}
