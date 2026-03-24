data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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
      Module      = "tf-aws-ecr"
    },
    var.tags
  )

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # Cross-account principals from var + current account always included
  all_pull_principals = concat(
    [for a in var.cross_account_ids : "arn:aws:iam::${a}:root"],
    var.additional_pull_principals
  )
}
