locals {
  name = var.name_prefix != "" ? "${var.name_prefix}-${var.name}-${var.environment}" : "${var.name}-${var.environment}"

  tags = merge(
    {
      Name        = local.name
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
    },
    var.tags
  )
}
