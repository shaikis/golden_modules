variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "myapp"
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
variable "enable_model_invocation_logging" {
  type    = bool
  default = false
}
variable "invocation_log_s3_bucket" {
  type    = string
  default = null
}
variable "invocation_log_retention_days" {
  type    = number
  default = 90
}

variable "guardrails" {
  type = map(object({
    description            = optional(string, "")
    blocked_input_message  = optional(string, "Sorry, this input is not allowed.")
    blocked_output_message = optional(string, "Sorry, this response cannot be provided.")
    kms_key_arn            = optional(string, null)
    topic_policy_topics = optional(list(object({
      name       = string
      definition = string
      type       = string
      examples   = optional(list(string), [])
    })), [])
    content_policy_filters = optional(list(object({
      type            = string
      input_strength  = string
      output_strength = string
    })), [])
    managed_word_lists = optional(list(string), ["PROFANITY"])
    custom_words       = optional(list(string), [])
    sensitive_information_policy_config = optional(list(object({
      type   = string
      action = string
    })), [])
  }))
  default = {}
}

variable "knowledge_bases" {
  type = map(object({
    description                  = optional(string, "")
    embedding_model_arn          = optional(string, "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v1")
    storage_type                 = optional(string, "OPENSEARCH_SERVERLESS")
    opensearch_collection_arn    = optional(string, null)
    opensearch_vector_index_name = optional(string, "bedrock-knowledge-base-default-index")
    opensearch_field_mapping = optional(object({
      vector_field   = optional(string, "bedrock-knowledge-base-default-vector")
      text_field     = optional(string, "AMAZON_BEDROCK_TEXT_CHUNK")
      metadata_field = optional(string, "AMAZON_BEDROCK_METADATA")
    }), {})
    s3_data_sources = optional(list(object({
      bucket_arn         = string
      key_prefixes       = optional(list(string), [])
      chunking_strategy  = optional(string, "FIXED_SIZE")
      max_tokens         = optional(number, 300)
      overlap_percentage = optional(number, 20)
    })), [])
  }))
  default = {}
}

variable "agents" {
  type = map(object({
    description        = optional(string, "")
    foundation_model   = string
    instruction        = string
    idle_session_ttl   = optional(number, 600)
    knowledge_base_ids = optional(list(string), [])
    guardrail_key      = optional(string, null)
    action_groups = optional(list(object({
      name        = string
      description = optional(string, "")
      lambda_arn  = optional(string, null)
      api_schema = optional(object({
        s3_bucket = string
        s3_key    = string
      }), null)
      function_schema = optional(any, null)
    })), [])
  }))
  default = {}
}
