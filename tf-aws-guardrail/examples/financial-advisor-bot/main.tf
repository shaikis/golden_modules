# =============================================================================
# SCENARIO: Fintech Financial Advisor Chatbot
#
# A regulated financial services firm deploys an AI assistant for retail
# investors. Strict SEC/FINRA compliance requirements:
#   - NEVER give specific investment/buy/sell recommendations
#   - NEVER discuss competitor financial products by name
#   - Block all PII: SSN, bank accounts, routing numbers, IBAN
#   - Prevent prompt injection attacks (adversarial users)
#   - Block hate, misconduct, and fraud-related language
#   - Proprietary data — block internal account numbers from appearing in output
# =============================================================================

provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name        = "${var.name}-guardrail"
  environment = var.environment
}

module "financial_advisor_guardrail" {
  source      = "../../"
  name        = "financial-advisor"
  name_prefix = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  kms_key_arn = module.kms.key_arn

  description = "SEC/FINRA compliant guardrail for retail investor AI assistant"

  blocked_input_message  = "I'm not authorized to assist with that request. Our AI assistant provides general financial education only. For personalized investment advice, please consult a licensed financial advisor."
  blocked_output_message = "I cannot provide that information as it may constitute investment advice. Please speak with a registered investment advisor or call 1-800-FINANCE."

  # SEC/FINRA compliance — deny regulated activities
  denied_topics = [
    {
      name       = "specific-investment-advice"
      definition = "Recommending specific stocks, ETFs, mutual funds, bonds, crypto assets, or any financial instrument to buy, sell, or hold."
      examples = [
        "Should I buy Apple stock now?",
        "Is Bitcoin a good investment?",
        "Which mutual fund should I put my 401k in?",
        "Tell me what to invest in to retire early."
      ]
    },
    {
      name       = "competitor-products"
      definition = "Discussing or recommending competitor financial products, brokerage accounts, or investment platforms by name."
      examples = [
        "Is Fidelity better than you?",
        "Should I move my money to Schwab?",
        "Compare your fees to Vanguard."
      ]
    },
    {
      name       = "tax-advice"
      definition = "Providing specific tax advice, tax avoidance strategies, or filing recommendations."
      examples = [
        "How do I avoid capital gains tax?",
        "Can I deduct this investment loss?",
        "Should I move my money offshore for tax purposes?"
      ]
    },
    {
      name       = "market-prediction"
      definition = "Making predictions about market movements, stock price targets, or economic forecasts."
      examples = [
        "Will the market crash this year?",
        "What will the S&P 500 be at end of year?",
        "Is a recession coming?"
      ]
    }
  ]

  # Financial platform abuse prevention
  content_filters = [
    { type = "HATE",          input_strength = "HIGH",   output_strength = "HIGH" },
    { type = "INSULTS",       input_strength = "MEDIUM", output_strength = "HIGH" },
    { type = "MISCONDUCT",    input_strength = "HIGH",   output_strength = "HIGH" },
    { type = "VIOLENCE",      input_strength = "MEDIUM", output_strength = "HIGH" },
    { type = "SEXUAL",        input_strength = "HIGH",   output_strength = "HIGH" },
    { type = "PROMPT_ATTACK", input_strength = "HIGH",   output_strength = "NONE" },
  ]

  managed_word_lists = ["PROFANITY"]

  # Fraud/compliance custom blocks
  custom_words = [
    "insider trading",
    "front running",
    "pump and dump",
    "money laundering",
    "wash trading",
  ]

  # Financial PII — strict blocking of all account identifiers
  pii_entities = [
    { type = "NAME",                          action = "ANONYMIZE" },
    { type = "EMAIL",                         action = "ANONYMIZE" },
    { type = "PHONE",                         action = "ANONYMIZE" },
    { type = "ADDRESS",                       action = "ANONYMIZE" },
    { type = "US_SOCIAL_SECURITY_NUMBER",     action = "BLOCK" },
    { type = "US_BANK_ACCOUNT_NUMBER",        action = "BLOCK" },
    { type = "US_BANK_ROUTING_NUMBER",        action = "BLOCK" },
    { type = "CREDIT_DEBIT_CARD_NUMBER",      action = "BLOCK" },
    { type = "CREDIT_DEBIT_CARD_CVV",         action = "BLOCK" },
    { type = "CREDIT_DEBIT_CARD_EXPIRY",      action = "BLOCK" },
    { type = "INTERNATIONAL_BANK_ACCOUNT_NUMBER", action = "BLOCK" },
    { type = "SWIFT_CODE",                    action = "BLOCK" },
    { type = "PASSWORD",                      action = "BLOCK" },
    { type = "PIN",                           action = "BLOCK" },
    { type = "US_INDIVIDUAL_TAX_IDENTIFICATION_NUMBER", action = "BLOCK" },
  ]

  # Internal account number pattern (e.g. ACC-20240001) — prevent exposure
  regex_patterns = [
    {
      name        = "internal-account-number"
      pattern     = "ACC-\\d{8}"
      description = "Internal brokerage account numbers"
      action      = "BLOCK"
    },
    {
      name        = "portfolio-id"
      pattern     = "PF-[A-Z]{2}\\d{6}"
      description = "Internal portfolio IDs (e.g. PF-US123456)"
      action      = "BLOCK"
    }
  ]

  create_version = true
}

output "guardrail_id"      { value = module.financial_advisor_guardrail.guardrail_id }
output "guardrail_arn"     { value = module.financial_advisor_guardrail.guardrail_arn }
output "guardrail_version" { value = module.financial_advisor_guardrail.guardrail_version }
