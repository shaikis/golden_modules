# ── CloudWatch Alarms ─────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "errors" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name}-errors"
  alarm_description   = "Lambda errors >= ${var.alarm_error_threshold} for ${local.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alarm_error_threshold
  treat_missing_data  = "notBreaching"

  dimensions = { FunctionName = aws_lambda_function.this.function_name }

  alarm_actions = local.effective_alarm_actions
  ok_actions    = local.effective_alarm_actions

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "throttles" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name}-throttles"
  alarm_description   = "Lambda throttles >= ${var.alarm_throttle_threshold} for ${local.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alarm_throttle_threshold
  treat_missing_data  = "notBreaching"

  dimensions = { FunctionName = aws_lambda_function.this.function_name }

  alarm_actions = local.effective_alarm_actions
  ok_actions    = local.effective_alarm_actions

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "duration" {
  count = var.create_cloudwatch_alarms && var.alarm_duration_threshold_ms > 0 ? 1 : 0

  alarm_name          = "${local.name}-duration"
  alarm_description   = "Lambda avg duration >= ${var.alarm_duration_threshold_ms}ms for ${local.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.alarm_duration_threshold_ms
  treat_missing_data  = "notBreaching"

  dimensions = { FunctionName = aws_lambda_function.this.function_name }

  alarm_actions = local.effective_alarm_actions
  ok_actions    = local.effective_alarm_actions

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "concurrent_executions" {
  count = var.create_cloudwatch_alarms && var.reserved_concurrent_executions > 0 ? 1 : 0

  alarm_name          = "${local.name}-concurrency"
  alarm_description   = "Lambda concurrency approaching reserved limit (${var.reserved_concurrent_executions}) for ${local.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = var.alarm_period_seconds
  statistic           = "Maximum"
  threshold           = floor(var.reserved_concurrent_executions * 0.8)
  treat_missing_data  = "notBreaching"

  dimensions = { FunctionName = aws_lambda_function.this.function_name }

  alarm_actions = local.effective_alarm_actions

  tags = local.tags
}
