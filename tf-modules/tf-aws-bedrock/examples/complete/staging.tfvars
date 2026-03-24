# staging — same env, slightly larger retention, guardrails enabled
aws_region  = "us-east-1"
name        = "platform-ai"
environment = "staging"
project     = "platform"
owner       = "ai-team"
cost_center = "CC-500"

enable_model_invocation_logging = true
invocation_log_s3_bucket        = "platform-staging-bedrock-logs"
invocation_log_retention_days   = 60

guardrails = {
  standard = {
    description            = "Standard content guardrail"
    blocked_input_message  = "This request is not allowed."
    blocked_output_message = "This response is not available."
    content_policy_filters = [
      { type = "HATE";     input_strength = "HIGH";   output_strength = "HIGH" },
      { type = "VIOLENCE"; input_strength = "MEDIUM"; output_strength = "MEDIUM" }
    ]
    managed_word_lists = ["PROFANITY"]
    sensitive_information_policy_config = [
      { type = "EMAIL";   action = "ANONYMIZE" },
      { type = "PHONE";   action = "ANONYMIZE" }
    ]
  }
}

knowledge_bases = {
  docs = {
    description               = "Internal documentation knowledge base"
    opensearch_collection_arn = "arn:aws:aoss:us-east-1:111122223333:collection/stg-kb"
    s3_data_sources = [{
      bucket_arn        = "arn:aws:s3:::platform-staging-docs"
      key_prefixes      = ["docs/"]
      chunking_strategy = "FIXED_SIZE"
      max_tokens        = 300
    }]
  }
}

agents = {
  support = {
    foundation_model   = "anthropic.claude-3-sonnet-20240229-v1:0"
    instruction        = "You are a helpful support assistant. Answer user questions using the knowledge base."
    idle_session_ttl   = 600
    knowledge_base_ids = []
    guardrail_key      = "standard"
  }
}
