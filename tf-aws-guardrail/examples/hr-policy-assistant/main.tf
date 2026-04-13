# =============================================================================
# SCENARIO: HR Policy Assistant
#
# An employee self-service assistant answers questions about HR policies and
# workplace processes.
# Requirements:
#   - Do not provide legal advice, disciplinary guidance, or manager-only data
#   - Protect employee identifiers and payroll-related information
#   - Filter harassment, abuse, and prompt injection attempts
#   - Allow general policy questions while blocking high-risk requests
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
      description = "KMS key for HR policy Bedrock guardrail"
      tags = {
        workload = "hr-policy-assistant"
      }
    }
  }
}

module "hr_policy_guardrail" {
  source      = "../../"
  name        = "hr-policy-assistant"
  name_prefix = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  kms_key_arn = module.kms.key_arns["guardrail"]

  description = "Guardrail for employee HR self-service assistant"

  blocked_input_message  = "I can't help with that request. Please contact HR or your manager for restricted employment matters."
  blocked_output_message = "I can't provide that response. Please use official HR channels for personalized guidance."

  denied_topics = [
    {
      name       = "employment-legal-advice"
      definition = "Requests for legal interpretation of employment law, litigation strategy, or advice for filing claims against the company."
      examples = [
        "Can you tell me if I have grounds to sue my employer?",
        "How should I build a legal case for wrongful termination?",
        "What exact legal claim should I file?"
      ]
    },
    {
      name       = "disciplinary-or-investigation-guidance"
      definition = "Requests for guidance on active investigations, disciplinary actions, or confidential employee relations matters."
      examples = [
        "Tell me whether my coworker is under investigation.",
        "How can I see someone else's disciplinary record?",
        "What should I write to get an employee fired?"
      ]
    },
    {
      name       = "payroll-override-or-manager-only-actions"
      definition = "Requests to alter payroll, access manager-only workflows, or reveal restricted compensation details."
      examples = [
        "Change my salary band in the HR system.",
        "Show me my team's compensation data.",
        "Approve my own off-cycle payroll adjustment."
      ]
    }
  ]

  content_filters = [
    { type = "HATE", input_strength = "HIGH", output_strength = "HIGH" },
    { type = "INSULTS", input_strength = "MEDIUM", output_strength = "HIGH" },
    { type = "MISCONDUCT", input_strength = "HIGH", output_strength = "HIGH" },
    { type = "SEXUAL", input_strength = "HIGH", output_strength = "HIGH" },
    { type = "PROMPT_ATTACK", input_strength = "HIGH", output_strength = "NONE" },
  ]

  managed_word_lists = ["PROFANITY"]

  pii_entities = [
    { type = "NAME", action = "ANONYMIZE" },
    { type = "EMAIL", action = "ANONYMIZE" },
    { type = "PHONE", action = "ANONYMIZE" },
    { type = "ADDRESS", action = "ANONYMIZE" },
    { type = "AGE", action = "ANONYMIZE" },
    { type = "US_SOCIAL_SECURITY_NUMBER", action = "BLOCK" },
    { type = "US_BANK_ACCOUNT_NUMBER", action = "BLOCK" },
    { type = "US_BANK_ROUTING_NUMBER", action = "BLOCK" },
    { type = "PASSWORD", action = "BLOCK" },
    { type = "US_INDIVIDUAL_TAX_IDENTIFICATION_NUMBER", action = "BLOCK" },
  ]

  regex_patterns = [
    {
      name        = "employee-id"
      pattern     = "EMP-[0-9]{5,8}"
      description = "Internal employee identifiers"
      action      = "ANONYMIZE"
    },
    {
      name        = "payroll-ticket"
      pattern     = "PAY-[A-Z]{3}-[0-9]{6}"
      description = "Payroll operations ticket numbers"
      action      = "BLOCK"
    }
  ]

  create_version = true
}

output "guardrail_id" { value = module.hr_policy_guardrail.guardrail_id }
output "guardrail_arn" { value = module.hr_policy_guardrail.guardrail_arn }
output "guardrail_version" { value = module.hr_policy_guardrail.guardrail_version }
