# =============================================================================
# tf-aws-cloudwatch — Core Locals
# =============================================================================

locals {
  # Full resource name prefix: "<name_prefix>-<name>" or just "<name>"
  prefix = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  # Common tags applied to every resource in the module
  common_tags = merge(
    {
      Name        = local.prefix
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Module      = "tf-aws-cloudwatch"
    },
    var.tags
  )

  # ── SNS Resolution ──────────────────────────────────────────────────────────
  # Priority: BYO topic ARN > module-created topic > null
  effective_sns_arn = var.sns_topic_arn != null ? var.sns_topic_arn : (
    var.create_sns_topic ? try(aws_sns_topic.this[0].arn, null) : null
  )

  # Default alarm actions: all alarms use the module SNS topic unless overridden per-alarm
  default_alarm_actions = local.effective_sns_arn != null ? [local.effective_sns_arn] : []
}
