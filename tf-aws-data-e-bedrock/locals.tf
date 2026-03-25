data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name       = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  tags = merge(
    {
      Name        = local.name
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Module      = "tf-aws-bedrock"
    },
    var.tags
  )
}
