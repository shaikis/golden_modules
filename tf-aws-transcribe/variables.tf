# ---------------------------------------------------------------------------
# Feature gates
# ---------------------------------------------------------------------------

variable "create_vocabularies" {
  description = "Set true to create custom vocabularies for improving transcription accuracy."
  type        = bool
  default     = false
}

variable "create_vocabulary_filters" {
  description = "Set true to create vocabulary filters (word masking/removal)."
  type        = bool
  default     = false
}

variable "create_language_models" {
  description = "Set true to create custom language models."
  type        = bool
  default     = false
}

variable "create_medical_vocabularies" {
  description = "Set true to create medical-specific vocabularies."
  type        = bool
  default     = false
}

variable "create_iam_role" {
  description = "Auto-create IAM role. Set false to BYO role_arn."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# BYO / shared resources
# ---------------------------------------------------------------------------

variable "role_arn" {
  description = "Existing IAM role ARN from tf-aws-iam. Used when create_iam_role = false."
  type        = string
  default     = null

  validation {
    condition     = var.role_arn == null || can(regex("^arn:[a-z\\-]+:iam::[0-9]{12}:role/.+", var.role_arn))
    error_message = "role_arn must be a valid IAM role ARN (arn:<partition>:iam::<account>:role/<name>) or null."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN from tf-aws-kms for output encryption. null = no encryption."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:[a-z\\-]+:kms:", var.kms_key_arn))
    error_message = "kms_key_arn must be a valid KMS key ARN or null."
  }
}

# ---------------------------------------------------------------------------
# Common
# ---------------------------------------------------------------------------

variable "name_prefix" {
  description = "Optional prefix prepended to all resource names."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags merged onto all resources."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Resource-specific variables
# ---------------------------------------------------------------------------

variable "vocabularies" {
  description = "Map of custom vocabularies. Requires create_vocabularies = true."
  type = map(object({
    language_code       = string
    phrases             = optional(list(string), [])
    vocabulary_file_uri = optional(string, null)
    tags                = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.vocabularies :
      length(v.phrases) > 0 || v.vocabulary_file_uri != null
    ])
    error_message = "Each vocabulary must supply at least one of: phrases (non-empty list) or vocabulary_file_uri."
  }
}

variable "vocabulary_filters" {
  description = "Map of vocabulary filters for word masking/removal. Requires create_vocabulary_filters = true."
  type = map(object({
    language_code              = string
    words                      = optional(list(string), [])
    vocabulary_filter_file_uri = optional(string, null)
    tags                       = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.vocabulary_filters :
      length(v.words) > 0 || v.vocabulary_filter_file_uri != null
    ])
    error_message = "Each vocabulary filter must supply at least one of: words (non-empty list) or vocabulary_filter_file_uri."
  }
}

variable "language_models" {
  description = "Map of custom language models. Requires create_language_models = true."
  type = map(object({
    language_code      = string
    base_model_name    = string
    s3_uri             = string
    tuning_data_s3_uri = optional(string, null)
    tags               = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.language_models :
      contains(["NarrowBand", "WideBand"], v.base_model_name)
    ])
    error_message = "base_model_name must be either 'NarrowBand' or 'WideBand'."
  }

  validation {
    condition = alltrue([
      for k, v in var.language_models :
      can(regex("^s3://", v.s3_uri))
    ])
    error_message = "s3_uri must be a valid S3 URI starting with 's3://'."
  }
}

variable "medical_vocabularies" {
  description = "Map of medical custom vocabularies. Requires create_medical_vocabularies = true. Only 'en-US' is supported."
  type = map(object({
    language_code       = string
    vocabulary_file_uri = string
    tags                = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.medical_vocabularies :
      v.language_code == "en-US"
    ])
    error_message = "Medical vocabularies only support language_code = 'en-US'."
  }

  validation {
    condition = alltrue([
      for k, v in var.medical_vocabularies :
      can(regex("^s3://", v.vocabulary_file_uri))
    ])
    error_message = "vocabulary_file_uri must be a valid S3 URI starting with 's3://'."
  }
}
