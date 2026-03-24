# =============================================================================
# tf-aws-cloudwatch — Data Sources
# Shared across all feature files.
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}
