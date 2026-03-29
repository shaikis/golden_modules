# =============================================================================
# SCENARIO: E-Commerce Customer Support Chatbot
#
# A retail company deploys a Claude-powered support bot on their website.
# Requirements:
#   - Block questions about competitors or pricing comparisons
#   - Remove PII (email, phone, credit card) from all conversations
#   - Block hate speech, insults, and jailbreak attempts
#   - Block profanity and known harmful phrases
# =============================================================================

provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name        = "${var.name}-guardrail"
  environment = var.environment
}

module "customer_support_guardrail" {
  source      = "../../"
  name        = "customer-support"
  name_prefix = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  kms_key_arn = module.kms.key_arn

  description            = "Guardrail for e-commerce customer support chatbot"
  blocked_input_message  = "I'm sorry, I can't help with that request. For further assistance, please contact our support team at support@example.com or call 1-800-EXAMPLE."
  blocked_output_message = "I wasn't able to generate a suitable response. Please try rephrasing your question or contact our support team directly."

  # Block competitor comparisons and pricing discussions
  denied_topics = [
    {
      name       = "competitor-comparison"
      definition = "Comparing our products, services, or pricing to a competitor or asking which brand/company is better."
      examples = [
        "Is your product better than Amazon?",
        "How does your price compare to Walmart?",
        "Which is cheaper, you or eBay?",
        "Should I buy from you or a competitor?"
      ]
    },
    {
      name       = "investment-or-financial-advice"
      definition = "Asking for investment advice, stock tips, or recommendations to buy/sell financial instruments."
      examples = [
        "Should I invest my money in your stock?",
        "What is your company's financial forecast?"
      ]
    }
  ]

  # Content safety — high bar for hate/insults, detect jailbreaks
  content_filters = [
    { type = "HATE",          input_strength = "HIGH",   output_strength = "HIGH" },
    { type = "INSULTS",       input_strength = "MEDIUM", output_strength = "HIGH" },
    { type = "VIOLENCE",      input_strength = "MEDIUM", output_strength = "MEDIUM" },
    { type = "SEXUAL",        input_strength = "HIGH",   output_strength = "HIGH" },
    { type = "MISCONDUCT",    input_strength = "MEDIUM", output_strength = "MEDIUM" },
    { type = "PROMPT_ATTACK", input_strength = "HIGH",   output_strength = "NONE" },
  ]

  # Block profanity automatically
  managed_word_lists = ["PROFANITY"]

  # Brand-safe custom blocks
  custom_words = [
    "scam",
    "fraud",
    "lawsuit",
    "class action",
  ]

  # Anonymize PII — protect customer data in conversation logs
  pii_entities = [
    { type = "EMAIL",                    action = "ANONYMIZE" },
    { type = "PHONE",                    action = "ANONYMIZE" },
    { type = "NAME",                     action = "ANONYMIZE" },
    { type = "ADDRESS",                  action = "ANONYMIZE" },
    { type = "CREDIT_DEBIT_CARD_NUMBER", action = "BLOCK" },
    { type = "CREDIT_DEBIT_CARD_CVV",    action = "BLOCK" },
    { type = "CREDIT_DEBIT_CARD_EXPIRY", action = "BLOCK" },
    { type = "US_SOCIAL_SECURITY_NUMBER", action = "BLOCK" },
    { type = "PASSWORD",                 action = "BLOCK" },
  ]

  create_version = true
}

output "guardrail_id"      { value = module.customer_support_guardrail.guardrail_id }
output "guardrail_arn"     { value = module.customer_support_guardrail.guardrail_arn }
output "guardrail_version" { value = module.customer_support_guardrail.guardrail_version }
