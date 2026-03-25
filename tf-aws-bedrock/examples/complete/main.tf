provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name        = "${var.name}-bedrock"
  environment = var.environment
}

module "bedrock" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  kms_key_arn = module.kms.key_arn

  enable_model_invocation_logging = var.enable_model_invocation_logging
  invocation_log_s3_bucket        = var.invocation_log_s3_bucket
  invocation_log_retention_days   = var.invocation_log_retention_days

  guardrails      = var.guardrails
  knowledge_bases = var.knowledge_bases
  agents          = var.agents
}

output "agent_ids" { value = module.bedrock.agent_ids }
output "knowledge_base_ids" { value = module.bedrock.knowledge_base_ids }
output "guardrail_ids" { value = module.bedrock.guardrail_ids }
