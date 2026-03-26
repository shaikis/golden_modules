# ---------------------------------------------------------------------------
# Feature Gates
# ---------------------------------------------------------------------------

variable "create_document_classifiers" {
  description = "Set true to create Comprehend custom document classifiers."
  type        = bool
  default     = false
}

variable "create_entity_recognizers" {
  description = "Set true to create Comprehend custom entity recognizers."
  type        = bool
  default     = false
}

variable "create_iam_role" {
  description = "Auto-create IAM role. Set false to provide role_arn (BYO from tf-aws-iam)."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# BYO / Shared References
# ---------------------------------------------------------------------------

variable "role_arn" {
  description = "Existing IAM role ARN from tf-aws-iam. Used when create_iam_role = false."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN from tf-aws-kms for model encryption. null = no encryption."
  type        = string
  default     = null
}

variable "volume_kms_key_arn" {
  description = "KMS key ARN for volume encryption during training. null = no encryption."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Naming & Tagging
# ---------------------------------------------------------------------------

variable "name_prefix" {
  description = "Optional prefix prepended to all resource names."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Map of tags applied to all resources."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Document Classifiers
# ---------------------------------------------------------------------------

variable "document_classifiers" {
  description = "Map of custom document classifiers. Key becomes part of the resource name."
  type = map(object({
    language_code     = string                 # e.g. "en"
    mode              = optional(string, "MULTI_CLASS") # MULTI_CLASS or MULTI_LABEL
    s3_uri            = string                 # S3 URI for training data
    test_s3_uri       = optional(string, null) # S3 URI for test data
    label_delimiter   = optional(string, null) # Required for MULTI_LABEL
    version_name      = optional(string, null)
    model_kms_key_id  = optional(string, null) # Overrides var.kms_key_arn per-classifier
    volume_kms_key_id = optional(string, null) # Overrides var.volume_kms_key_arn per-classifier
    vpc_config = optional(object({
      security_group_ids = list(string)
      subnets            = list(string)
    }), null)
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.document_classifiers :
      contains(["MULTI_CLASS", "MULTI_LABEL"], v.mode)
    ])
    error_message = "document_classifiers[*].mode must be one of: MULTI_CLASS, MULTI_LABEL."
  }

  validation {
    condition = alltrue([
      for k, v in var.document_classifiers :
      contains([
        "af", "sq", "am", "ar", "hy", "as", "az", "ba", "eu", "be", "bn",
        "bs", "br", "bg", "ca", "zh", "zh-TW", "co", "hr", "cs", "da", "nl",
        "en", "eo", "et", "fi", "fr", "fy", "gl", "ka", "de", "el", "gu",
        "ht", "ha", "he", "hi", "hu", "is", "id", "ga", "it", "ja", "jv",
        "kn", "kk", "km", "ko", "ku", "ky", "lo", "la", "lv", "lt", "lb",
        "mk", "mg", "ms", "ml", "mt", "mi", "mr", "mn", "my", "ne", "no",
        "ps", "fa", "pl", "pt", "pa", "ro", "ru", "sm", "gd", "sr", "sn",
        "sd", "si", "sk", "sl", "so", "st", "es", "su", "sw", "sv", "tl",
        "tg", "ta", "tt", "te", "th", "ti", "tr", "tk", "uk", "ur", "ug",
        "uz", "vi", "cy", "xh", "yi", "yo", "zu"
      ], v.language_code)
    ])
    error_message = "document_classifiers[*].language_code must be a valid BCP-47 language tag supported by AWS Comprehend (e.g. \"en\", \"es\", \"fr\")."
  }
}

# ---------------------------------------------------------------------------
# Entity Recognizers
# ---------------------------------------------------------------------------

variable "entity_recognizers" {
  description = "Map of custom entity recognizers. Key becomes part of the resource name."
  type = map(object({
    language_code = string # "en", "es", "fr", etc.

    # Entity types the model will recognize — at least one required
    entity_types = list(object({
      type = string # e.g. "PRODUCT", "PERSON", "ORGANIZATION"
    }))

    # Training data sources (at least one of entity_list, annotations, or documents must be set)
    entity_list = optional(object({
      s3_uri = string
    }), null)

    annotations = optional(object({
      s3_uri      = string
      test_s3_uri = optional(string, null)
    }), null)

    documents = optional(object({
      s3_uri       = string
      test_s3_uri  = optional(string, null)
      input_format = optional(string, "ONE_DOC_PER_LINE")
    }), null)

    version_name      = optional(string, null)
    model_kms_key_id  = optional(string, null) # Overrides var.kms_key_arn per-recognizer
    volume_kms_key_id = optional(string, null) # Overrides var.volume_kms_key_arn per-recognizer

    vpc_config = optional(object({
      security_group_ids = list(string)
      subnets            = list(string)
    }), null)

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.entity_recognizers :
      length(v.entity_types) > 0
    ])
    error_message = "entity_recognizers[*].entity_types must contain at least one entry."
  }

  validation {
    condition = alltrue([
      for k, v in var.entity_recognizers :
      contains([
        "af", "sq", "am", "ar", "hy", "as", "az", "ba", "eu", "be", "bn",
        "bs", "br", "bg", "ca", "zh", "zh-TW", "co", "hr", "cs", "da", "nl",
        "en", "eo", "et", "fi", "fr", "fy", "gl", "ka", "de", "el", "gu",
        "ht", "ha", "he", "hi", "hu", "is", "id", "ga", "it", "ja", "jv",
        "kn", "kk", "km", "ko", "ku", "ky", "lo", "la", "lv", "lt", "lb",
        "mk", "mg", "ms", "ml", "mt", "mi", "mr", "mn", "my", "ne", "no",
        "ps", "fa", "pl", "pt", "pa", "ro", "ru", "sm", "gd", "sr", "sn",
        "sd", "si", "sk", "sl", "so", "st", "es", "su", "sw", "sv", "tl",
        "tg", "ta", "tt", "te", "th", "ti", "tr", "tk", "uk", "ur", "ug",
        "uz", "vi", "cy", "xh", "yi", "yo", "zu"
      ], v.language_code)
    ])
    error_message = "entity_recognizers[*].language_code must be a valid BCP-47 language tag supported by AWS Comprehend (e.g. \"en\", \"es\", \"fr\")."
  }

  validation {
    condition = alltrue([
      for k, v in var.entity_recognizers :
      v.entity_list != null || v.annotations != null || v.documents != null
    ])
    error_message = "entity_recognizers[*] must specify at least one training data source: entity_list, annotations, or documents."
  }
}
