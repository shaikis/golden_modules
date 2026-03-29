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
      Module      = "tf-aws-cloudfront"
    },
    var.tags
  )

  # Build the origin map: keyed by origin_id for clean cross-references
  origins_map = { for o in var.origins : o.origin_id => o }
}
