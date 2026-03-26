locals {
  prefix = "${var.name}-${var.environment}"

  tags = merge(var.tags, {
    Name        = local.prefix
    Environment = var.environment
    Solution    = "bedrock-agentcore-slack"
    ManagedBy   = "terraform"
  })

  kms_key_arn = var.enable_kms_encryption ? module.kms[0].key_arns["pipeline"] : null

  bedrock_guardrail_id      = var.enable_bedrock_guardrail ? module.bedrock.guardrail_ids["slack-agent"] : ""
  bedrock_guardrail_version = var.enable_bedrock_guardrail ? "DRAFT" : ""
}
