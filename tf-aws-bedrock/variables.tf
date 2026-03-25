variable "name" {
  type = string
}
variable "name_prefix" {
  type    = string
  default = ""
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
  type = map(string)
  default = {
  }
}

# ===========================================================================
# MODEL INVOCATION LOGGING
# ===========================================================================
variable "enable_model_invocation_logging" {
  type    = bool
  default = false
}

variable "invocation_log_s3_bucket" {
  type    = string
  default = null
}

variable "invocation_log_s3_prefix" {
  type    = string
  default = "bedrock-logs/"
}

variable "invocation_log_cloudwatch_log_group" {
  type    = string
  default = null
}

variable "invocation_log_retention_days" {
  type    = number
  default = 90
}

variable "kms_key_arn" {
  description = "KMS key for log encryption."
  type        = string
  default     = null
}

# ===========================================================================
# GUARDRAILS
# ===========================================================================
variable "guardrails" {
  description = "Map of guardrail name → config."
  type = map(object({
    description            = optional(string, "")
    blocked_input_message  = optional(string, "Sorry, this input is not allowed.")
    blocked_output_message = optional(string, "Sorry, this response cannot be provided.")
    kms_key_arn            = optional(string, null)

    # Topic policy
    topic_policy_topics = optional(list(object({
      name       = string
      definition = string
      type       = string # DENY
      examples   = optional(list(string), [])
    })), [])

    # Content filters
    content_policy_filters = optional(list(object({
      type            = string # SEXUAL | VIOLENCE | HATE | INSULTS | MISCONDUCT | PROMPT_ATTACK
      input_strength  = string # NONE | LOW | MEDIUM | HIGH
      output_strength = string
    })), [])

    # Word filters
    managed_word_lists = optional(list(string), ["PROFANITY"]) # managed list names
    custom_words       = optional(list(string), [])

    # PII redaction
    sensitive_information_policy_config = optional(list(object({
      type   = string # ADDRESS | AGE | EMAIL | etc.
      action = string # ANONYMIZE | BLOCK
    })), [])
  }))
  default = {}
}

# ===========================================================================
# KNOWLEDGE BASES
# ===========================================================================
variable "knowledge_bases" {
  description = "Map of knowledge base name → config."
  type = map(object({
    description         = optional(string, "")
    embedding_model_arn = optional(string, "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v1")
    storage_type        = optional(string, "OPENSEARCH_SERVERLESS") # OPENSEARCH_SERVERLESS | PINECONE | REDIS_ENTERPRISE_CLOUD | RDS

    # OpenSearch Serverless
    opensearch_collection_arn    = optional(string, null)
    opensearch_vector_index_name = optional(string, "bedrock-knowledge-base-default-index")
    opensearch_field_mapping = optional(object({
      vector_field   = optional(string, "bedrock-knowledge-base-default-vector")
      text_field     = optional(string, "AMAZON_BEDROCK_TEXT_CHUNK")
      metadata_field = optional(string, "AMAZON_BEDROCK_METADATA")
    }), {})

    # Data sources (S3)
    s3_data_sources = optional(list(object({
      bucket_arn         = string
      key_prefixes       = optional(list(string), [])
      chunking_strategy  = optional(string, "FIXED_SIZE") # FIXED_SIZE | NONE
      max_tokens         = optional(number, 300)
      overlap_percentage = optional(number, 20)
    })), [])
  }))
  default = {}
}

# ===========================================================================
# AGENTS
# ===========================================================================
variable "agents" {
  description = "Map of agent name → config."
  type = map(object({
    description        = optional(string, "")
    foundation_model   = string # e.g. "anthropic.claude-3-sonnet-20240229-v1:0"
    instruction        = string # Agent system prompt
    idle_session_ttl   = optional(number, 600)
    knowledge_base_ids = optional(list(string), []) # attach knowledge bases
    guardrail_key      = optional(string, null)     # key from var.guardrails

    # Action groups
    action_groups = optional(list(object({
      name        = string
      description = optional(string, "")
      lambda_arn  = optional(string, null)
      api_schema = optional(object({
        s3_bucket = string
        s3_key    = string
      }), null)
      function_schema = optional(object({
        functions = list(object({
          name        = string
          description = string
          parameters = optional(map(object({
            type        = string
            description = string
            required    = optional(bool, false)
          })), {})
        }))
      }), null)
    })), [])
  }))
  default = {}
}
