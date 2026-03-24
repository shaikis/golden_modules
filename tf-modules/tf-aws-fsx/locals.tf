locals {
  name = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  tags = merge(
    {
      Name        = local.name
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Module      = "tf-aws-fsx"
    },
    var.tags
  )
}
