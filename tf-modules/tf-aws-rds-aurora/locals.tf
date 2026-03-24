locals {
  name = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  default_tags = {
    Name        = local.name
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Module      = "tf-aws-rds-aurora"
  }
  tags = merge(local.default_tags, var.tags)

  is_serverless_v2 = var.engine_mode == "provisioned" && length(var.serverlessv2_scaling) > 0
}
