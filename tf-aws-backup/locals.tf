locals {
  name_prefix = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  common_tags = merge(
    {
      Name        = var.name
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
    },
    var.tags
  )

  # IAM: if existing ARN is provided → use it; else use the module-created role
  # Precedence: var.iam_role_arn (BYO) > module-created role
  iam_role_arn = var.iam_role_arn != null ? var.iam_role_arn : (
    var.create_iam_role ? aws_iam_role.backup[0].arn : null
  )

  # SNS: if existing ARN is provided → use it; else use module-created topic; else null
  # Precedence: var.sns_topic_arn (BYO) > module-created topic > null (no notifications)
  effective_sns_topic_arn = var.sns_topic_arn != null ? var.sns_topic_arn : (
    var.create_sns_topic && var.sns_topic_arn == null ? aws_sns_topic.this[0].arn : null
  )

  alarm_actions_list = length(var.alarm_actions) > 0 ? var.alarm_actions : (
    local.effective_sns_topic_arn != null ? [local.effective_sns_topic_arn] : []
  )
}
