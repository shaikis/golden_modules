aws_region  = "us-east-1"
name        = "platform-ai"
environment = "prod"
project     = "platform"
owner       = "ai-team"
cost_center = "CC-500"

enable_model_invocation_logging = true
invocation_log_s3_bucket        = "platform-prod-bedrock-logs"
invocation_log_retention_days   = 90

guardrails = {
  standard = {
    description = "Production content guardrail"
    content_policy_filters = [
      { type = "HATE";            input_strength = "HIGH"; output_strength = "HIGH" },
      { type = "VIOLENCE";        input_strength = "HIGH"; output_strength = "HIGH" },
      { type = "SEXUAL";          input_strength = "HIGH"; output_strength = "HIGH" },
      { type = "MISCONDUCT";      input_strength = "HIGH"; output_strength = "HIGH" },
      { type = "PROMPT_ATTACK";   input_strength = "HIGH"; output_strength = "NONE" }
    ]
    managed_word_lists = ["PROFANITY"]
    sensitive_information_policy_config = [
      { type = "EMAIL";          action = "ANONYMIZE" },
      { type = "PHONE";          action = "ANONYMIZE" },
      { type = "CREDIT_DEBIT_CARD_NUMBER"; action = "BLOCK" },
      { type = "SSN";            action = "BLOCK" }
    ]
  }
}

knowledge_bases = {
  docs = {
    description               = "Internal documentation knowledge base"
    opensearch_collection_arn = "arn:aws:aoss:us-east-1:111122223333:collection/prod-kb"
    s3_data_sources = [{
      bucket_arn        = "arn:aws:s3:::platform-prod-docs"
      key_prefixes      = ["docs/", "kb/"]
      chunking_strategy = "FIXED_SIZE"
      max_tokens        = 300
    }]
  }
}

agents = {
  support = {
    foundation_model = "anthropic.claude-3-sonnet-20240229-v1:0"
    instruction      = "You are a professional support agent. Respond concisely and accurately."
    idle_session_ttl = 600
    guardrail_key    = "standard"
    action_groups = [{
      name        = "GetTicketStatus"
      description = "Retrieve support ticket status from backend API"
      lambda_arn  = "arn:aws:lambda:us-east-1:111122223333:function:bedrock-get-ticket"
      api_schema  = {
        s3_bucket = "platform-prod-bedrock-schemas"
        s3_key    = "agents/support/openapi.json"
      }
    }]
  }
}
