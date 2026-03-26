# ── Feature Gates ─────────────────────────────────────────────────────────────
variable "create_iam_role" {
  description = "Auto-create IAM role for Textract API access. Set false to BYO role_arn."
  type        = bool
  default     = true
}

variable "create_sns_topics" {
  description = "Set true to create SNS topics for async Textract job completion notifications."
  type        = bool
  default     = false
}

variable "create_sqs_queues" {
  description = "Set true to create SQS queues for receiving Textract async job results."
  type        = bool
  default     = false
}

variable "create_alarms" {
  description = "Set true to create CloudWatch alarms for Textract job monitoring."
  type        = bool
  default     = false
}

# ── BYO Pattern ───────────────────────────────────────────────────────────────
variable "role_arn" {
  description = "Existing IAM role ARN from tf-aws-iam. Used when create_iam_role = false."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN from tf-aws-kms for SNS/SQS encryption. null = no encryption."
  type        = string
  default     = null
}

# ── Global ────────────────────────────────────────────────────────────────────
variable "name_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

# ── SNS Topics ────────────────────────────────────────────────────────────────
variable "sns_topics" {
  description = "Map of SNS topics for Textract async job notifications."
  type = map(object({
    display_name      = optional(string, null)
    kms_master_key_id = optional(string, null)
    tags              = optional(map(string), {})
  }))
  default = {}
}

# ── SQS Queues ────────────────────────────────────────────────────────────────
variable "sqs_queues" {
  description = "Map of SQS queues for Textract result processing."
  type = map(object({
    visibility_timeout_seconds = optional(number, 300)
    message_retention_seconds  = optional(number, 86400)
    kms_master_key_id          = optional(string, null)
    create_dlq                 = optional(bool, false)
    tags                       = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.sqs_queues :
      v.visibility_timeout_seconds >= 0 && v.visibility_timeout_seconds <= 43200
    ])
    error_message = "visibility_timeout_seconds must be between 0 and 43200 seconds."
  }

  validation {
    condition = alltrue([
      for k, v in var.sqs_queues :
      v.message_retention_seconds >= 60 && v.message_retention_seconds <= 1209600
    ])
    error_message = "message_retention_seconds must be between 60 seconds (1 minute) and 1209600 seconds (14 days)."
  }
}

# ── IAM ───────────────────────────────────────────────────────────────────────
variable "trusted_principals" {
  description = "Additional IAM principals trusted to assume the Textract role."
  type        = list(string)
  default     = []
}

variable "s3_input_bucket_arns" {
  description = "S3 bucket ARNs that Textract can read documents from."
  type        = list(string)
  default     = []
}

variable "s3_output_bucket_arns" {
  description = "S3 bucket ARNs that Textract can write results to."
  type        = list(string)
  default     = []
}

# ── Alarms ────────────────────────────────────────────────────────────────────
variable "alarm_sns_arns" {
  description = "SNS topic ARNs for CloudWatch alarm notifications."
  type        = list(string)
  default     = []
}
