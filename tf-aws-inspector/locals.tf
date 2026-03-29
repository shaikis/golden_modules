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
      Module      = "tf-aws-inspector"
    },
    var.tags
  )

  # Aggregate all member account IDs for enablement
  all_member_account_ids = [for m in var.member_accounts : m.account_id]
}
