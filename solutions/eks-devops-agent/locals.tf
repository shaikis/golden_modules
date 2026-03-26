locals {
  prefix = "${var.name}-${var.environment}"

  tags = merge(var.tags, {
    Name        = local.prefix
    Environment = var.environment
    Solution    = "eks-devops-agent"
    ManagedBy   = "terraform"
  })

  # KMS key ARN — null when KMS is disabled so modules fall back to AWS-managed keys
  kms_key_arn = var.enable_kms ? module.kms[0].key_arns["eks-observability"] : null
}
