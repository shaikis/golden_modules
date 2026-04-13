# =============================================================================
# SCENARIO: Healthcare Patient Q&A Assistant
#
# A hospital deploys a Claude-powered assistant for general health questions.
# Requirements:
#   - NEVER prescribe medications or give specific medical advice
#   - Strictly block PHI (HIPAA): SSN, DOB, medical record numbers
#   - Detect hallucinations — responses must be grounded in retrieved docs
#   - Block violence, self-harm adjacent misconduct content
#   - Redirect emergencies to 911
# =============================================================================

provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name_prefix = "${var.environment}/${var.name}"
  tags = {
    project     = var.project
    owner       = var.owner
    cost_center = var.cost_center
    environment = var.environment
  }
  keys = {
    guardrail = {
      description = "KMS key for healthcare Bedrock guardrail"
      tags = {
        workload = "healthcare-assistant"
      }
    }
  }
}

module "healthcare_guardrail" {
  source      = "../../"
  name        = "healthcare-assistant"
  name_prefix = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  kms_key_arn = module.kms.key_arns["guardrail"]

  description = "Guardrail for hospital patient Q&A assistant — HIPAA compliant"

  blocked_input_message  = "I'm not able to assist with that question. For urgent medical concerns please call 911 or contact your healthcare provider directly."
  blocked_output_message = "I cannot provide that medical information. Please consult your doctor or a licensed healthcare professional for personalized advice."

  # Deny specific high-risk medical topics
  denied_topics = [
    {
      name       = "prescription-advice"
      definition = "Recommending, prescribing, or advising dosages for any medication, supplement, or controlled substance."
      examples = [
        "What dose of ibuprofen should I take?",
        "Can I take metformin with alcohol?",
        "How many Xanax can I take per day?"
      ]
    },
    {
      name       = "diagnosis"
      definition = "Diagnosing a specific medical condition based on symptoms or test results."
      examples = [
        "Based on my symptoms do I have diabetes?",
        "My blood pressure is 160/100, what disease do I have?",
        "I think I have cancer, can you confirm?"
      ]
    },
    {
      name       = "self-harm-guidance"
      definition = "Providing information that could facilitate self-harm or suicide."
      examples = [
        "What medications cause overdose?",
        "How can I hurt myself without being noticed?"
      ]
    }
  ]

  # Strict content filtering for healthcare context
  content_filters = [
    { type = "VIOLENCE", input_strength = "HIGH", output_strength = "HIGH" },
    { type = "MISCONDUCT", input_strength = "HIGH", output_strength = "HIGH" },
    { type = "HATE", input_strength = "HIGH", output_strength = "HIGH" },
    { type = "INSULTS", input_strength = "MEDIUM", output_strength = "HIGH" },
    { type = "SEXUAL", input_strength = "HIGH", output_strength = "HIGH" },
    { type = "PROMPT_ATTACK", input_strength = "HIGH", output_strength = "NONE" },
  ]

  managed_word_lists = ["PROFANITY"]

  # HIPAA PHI — block or anonymize all personal health identifiers
  pii_entities = [
    { type = "NAME", action = "ANONYMIZE" },
    { type = "ADDRESS", action = "ANONYMIZE" },
    { type = "EMAIL", action = "ANONYMIZE" },
    { type = "PHONE", action = "ANONYMIZE" },
    { type = "AGE", action = "ANONYMIZE" },
    { type = "DATE_TIME", action = "ANONYMIZE" },
    { type = "US_SOCIAL_SECURITY_NUMBER", action = "BLOCK" },
    { type = "PASSWORD", action = "BLOCK" },
    { type = "USERNAME", action = "ANONYMIZE" },
    { type = "IP_ADDRESS", action = "BLOCK" },
  ]

  # Custom regex — block medical record numbers (MRN) like MRN-123456
  regex_patterns = [
    {
      name        = "medical-record-number"
      pattern     = "MRN[-\\s]?\\d{5,10}"
      description = "Hospital medical record numbers"
      action      = "BLOCK"
    },
    {
      name        = "national-provider-id"
      pattern     = "NPI[-\\s]?\\d{10}"
      description = "National Provider Identifier numbers"
      action      = "ANONYMIZE"
    }
  ]

  # CRITICAL: Grounding check — all responses must be based on retrieved docs
  # This prevents hallucinated drug interactions or false diagnoses
  grounding_filter = {
    grounding_threshold = 0.80 # Strict: 80% grounding confidence required
    relevance_threshold = 0.75
  }

  create_version = true
}

output "guardrail_id" { value = module.healthcare_guardrail.guardrail_id }
output "guardrail_arn" { value = module.healthcare_guardrail.guardrail_arn }
output "guardrail_version" { value = module.healthcare_guardrail.guardrail_version }
