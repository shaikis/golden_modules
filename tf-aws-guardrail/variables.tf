variable "name" {
  description = "Name of the guardrail."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix prepended to name."
  type        = string
  default     = ""
}

variable "environment" {
  type    = string
  default = "dev"
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
  type    = map(string)
  default = {}
}

# ===========================================================================
# GUARDRAIL CORE
# ===========================================================================
variable "description" {
  description = "Human-readable description of the guardrail."
  type        = string
  default     = ""
}

variable "blocked_input_message" {
  description = "Message returned when a user input is blocked."
  type        = string
  default     = "I'm sorry, this input is not allowed. Please rephrase your request."
}

variable "blocked_output_message" {
  description = "Message returned when a model output is blocked."
  type        = string
  default     = "I'm sorry, I cannot provide this response. Please try a different question."
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting guardrail data. Leave null to use AWS-managed keys."
  type        = string
  default     = null
}

variable "create_version" {
  description = "Whether to publish a versioned snapshot of the guardrail."
  type        = bool
  default     = true
}

# ===========================================================================
# TOPIC POLICY - Deny specific conversation topics
# ===========================================================================
variable "denied_topics" {
  description = <<-EOT
    List of topics to deny. Each topic has:
      name       - short label
      definition - what the topic means (used by the LLM to detect it)
      examples   - optional list of example phrases that belong to this topic
  EOT
  type = list(object({
    name       = string
    definition = string
    examples   = optional(list(string), [])
  }))
  default = []
}

# ===========================================================================
# CONTENT FILTERS - Strength-based harmful content filtering
# ===========================================================================
variable "content_filters" {
  description = <<-EOT
    Content category filters. Supported types:
      SEXUAL | VIOLENCE | HATE | INSULTS | MISCONDUCT | PROMPT_ATTACK
    Supported strengths: NONE | LOW | MEDIUM | HIGH
  EOT
  type = list(object({
    type            = string
    input_strength  = string
    output_strength = string
  }))
  default = []
}

# ===========================================================================
# WORD FILTERS
# ===========================================================================
variable "managed_word_lists" {
  description = "AWS-managed word lists to enable. Currently supports: PROFANITY"
  type        = list(string)
  default     = []
}

variable "custom_words" {
  description = "List of custom words/phrases to block."
  type        = list(string)
  default     = []
}

# ===========================================================================
# PII / SENSITIVE INFORMATION
# ===========================================================================
variable "pii_entities" {
  description = <<-EOT
    PII entity types to detect and action on. Supported types:
      ADDRESS | AGE | AWS_ACCESS_KEY | AWS_SECRET_KEY | CA_HEALTH_NUMBER |
      CA_SOCIAL_INSURANCE_NUMBER | CREDIT_DEBIT_CARD_CVV | CREDIT_DEBIT_CARD_EXPIRY |
      CREDIT_DEBIT_CARD_NUMBER | DRIVER_ID | EMAIL | INTERNATIONAL_BANK_ACCOUNT_NUMBER |
      IP_ADDRESS | LICENSE_PLATE | MAC_ADDRESS | NAME | PASSWORD | PHONE | PIN |
      SWIFT_CODE | UK_NATIONAL_HEALTH_SERVICE_NUMBER | UK_NATIONAL_INSURANCE_NUMBER |
      UK_UNIQUE_TAXPAYER_REFERENCE_NUMBER | URL | USERNAME | US_BANK_ACCOUNT_NUMBER |
      US_BANK_ROUTING_NUMBER | US_INDIVIDUAL_TAX_IDENTIFICATION_NUMBER |
      US_PASSPORT_NUMBER | US_SOCIAL_SECURITY_NUMBER | VEHICLE_IDENTIFICATION_NUMBER
    Actions: ANONYMIZE | BLOCK
  EOT
  type = list(object({
    type   = string
    action = string
  }))
  default = []
}

variable "regex_patterns" {
  description = <<-EOT
    Custom regex patterns to detect and action on.
      name        - label for the pattern
      pattern     - valid Java regex
      description - optional description
      action      - ANONYMIZE | BLOCK
  EOT
  type = list(object({
    name        = string
    pattern     = string
    description = optional(string, "")
    action      = string
  }))
  default = []
}

# ===========================================================================
# GROUNDING CHECK (RAG hallucination detection)
# ===========================================================================
variable "grounding_filter" {
  description = <<-EOT
    Enable grounding check to detect model hallucinations against retrieved context.
      grounding_threshold  - 0.0–1.0, higher = stricter (default 0.75)
      relevance_threshold  - 0.0–1.0 (default 0.75)
  EOT
  type = object({
    grounding_threshold = optional(number, 0.75)
    relevance_threshold = optional(number, 0.75)
  })
  default = null
}
