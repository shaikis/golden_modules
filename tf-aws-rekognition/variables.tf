# ---------------------------------------------------------------------------
# Feature gates
# ---------------------------------------------------------------------------

variable "create_collections" {
  description = "Set true to create Rekognition face collections."
  type        = bool
  default     = false
}

variable "create_stream_processors" {
  description = "Set true to create Rekognition stream processors for video analysis."
  type        = bool
  default     = false
}

variable "create_custom_labels_projects" {
  description = "Set true to create Rekognition Custom Labels projects."
  type        = bool
  default     = false
}

variable "create_alarms" {
  description = "Set true to create CloudWatch alarms for stream processor errors."
  type        = bool
  default     = false
}

variable "create_iam_role" {
  description = "Auto-create IAM role for Rekognition. Set false and provide role_arn to BYO."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# BYO / shared resources
# ---------------------------------------------------------------------------

variable "role_arn" {
  description = "Existing IAM role ARN to use when create_iam_role = false."
  type        = string
  default     = null

  validation {
    condition     = var.role_arn == null || can(regex("^arn:[a-z0-9\\-]+:iam::[0-9]{12}:role/.+", var.role_arn))
    error_message = "role_arn must be a valid IAM role ARN (arn:<partition>:iam::<account>:role/<name>) or null."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (e.g. from tf-aws-kms). null = no customer-managed encryption."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:[a-z0-9\\-]+:kms:[a-z0-9\\-]+:[0-9]{12}:key/.+", var.kms_key_arn))
    error_message = "kms_key_arn must be a valid KMS key ARN or null."
  }
}

# ---------------------------------------------------------------------------
# Naming & tagging
# ---------------------------------------------------------------------------

variable "name_prefix" {
  description = "Optional prefix prepended to all resource names, e.g. 'prod'."
  type        = string
  default     = ""

  validation {
    condition     = length(var.name_prefix) <= 32
    error_message = "name_prefix must be 32 characters or fewer."
  }
}

variable "tags" {
  description = "Map of tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Collections
# ---------------------------------------------------------------------------

variable "collections" {
  description = <<-EOT
    Map of Rekognition face collections to create.
    Key = collection_id.
    Example:
      collections = {
        "prod-faces" = { tags = { Team = "security" } }
      }
  EOT
  type = map(object({
    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Stream processors
# ---------------------------------------------------------------------------

variable "stream_processors" {
  description = <<-EOT
    Map of Rekognition stream processors to create.
    Key = processor name.

    face_search and connected_home are mutually exclusive per processor.
    Omit connected_home_labels to default to face-search mode.

    Example:
      stream_processors = {
        "entrance-cam" = {
          kinesis_video_stream_arn  = "arn:aws:kinesisvideo:..."
          kinesis_data_stream_arn   = "arn:aws:kinesis:..."
          face_search = {
            collection_id        = "prod-faces"
            face_match_threshold = 90
          }
          notification_sns_arn = "arn:aws:sns:..."
          data_sharing_preference_opt_in = false
          regions_of_interest = []
          tags = {}
        }
      }
  EOT
  type = map(object({
    kinesis_video_stream_arn = string
    kinesis_data_stream_arn  = string
    face_search = optional(object({
      collection_id        = string
      face_match_threshold = optional(number, 80)
    }), null)
    connected_home_labels          = optional(list(string), null)
    connected_home_min_confidence  = optional(number, 55)
    notification_sns_arn           = optional(string, null)
    data_sharing_preference_opt_in = optional(bool, false)
    regions_of_interest = optional(list(object({
      left   = number
      top    = number
      width  = number
      height = number
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.stream_processors :
      !(v.face_search != null && v.connected_home_labels != null)
    ])
    error_message = "Each stream processor must use either face_search or connected_home_labels, not both."
  }
}

# ---------------------------------------------------------------------------
# Custom Labels projects
# ---------------------------------------------------------------------------

variable "custom_labels_projects" {
  description = <<-EOT
    Map of Rekognition Custom Labels projects to create.
    Key = project name.
    Example:
      custom_labels_projects = {
        "defect-detector" = { tags = { CostCenter = "ml" } }
      }
  EOT
  type = map(object({
    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Alarms
# ---------------------------------------------------------------------------

variable "alarm_sns_arns" {
  description = "List of SNS topic ARNs to notify when CloudWatch alarms fire."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.alarm_sns_arns :
      can(regex("^arn:[a-z0-9\\-]+:sns:[a-z0-9\\-]+:[0-9]{12}:.+", arn))
    ])
    error_message = "Every entry in alarm_sns_arns must be a valid SNS topic ARN."
  }
}

variable "alarm_error_threshold" {
  description = "Number of stream processor errors within the evaluation period before an alarm fires."
  type        = number
  default     = 1

  validation {
    condition     = var.alarm_error_threshold >= 1
    error_message = "alarm_error_threshold must be >= 1."
  }
}

variable "alarm_evaluation_periods" {
  description = "Number of consecutive evaluation periods that must breach the threshold."
  type        = number
  default     = 1

  validation {
    condition     = var.alarm_evaluation_periods >= 1
    error_message = "alarm_evaluation_periods must be >= 1."
  }
}

variable "alarm_period_seconds" {
  description = "Evaluation period duration in seconds for CloudWatch alarms."
  type        = number
  default     = 300

  validation {
    condition     = contains([10, 30, 60, 300, 600, 900, 3600], var.alarm_period_seconds)
    error_message = "alarm_period_seconds must be one of: 10, 30, 60, 300, 600, 900, 3600."
  }
}
