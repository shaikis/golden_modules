locals {
  name = var.name_prefix != "" ? "${var.name_prefix}-${var.bucket_name}" : var.bucket_name

  default_tags = {
    Name        = local.name
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Module      = "tf-aws-s3"
  }

  tags = merge(local.default_tags, var.tags)
}
