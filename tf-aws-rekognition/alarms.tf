# ---------------------------------------------------------------------------
# CloudWatch Alarms for Rekognition Stream Processor errors
# Controlled by: create_alarms = true
# ---------------------------------------------------------------------------

# One alarm per stream processor tracking the "Errors" metric published by
# Rekognition into the AWS/Rekognition namespace.
resource "aws_cloudwatch_metric_alarm" "stream_processor_errors" {
  for_each = var.create_alarms ? local.active_stream_processors : {}

  alarm_name          = "${local.name_prefix}rekognition-sp-errors-${each.key}"
  alarm_description   = "Fires when Rekognition stream processor '${each.key}' reports errors."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "Errors"
  namespace           = "AWS/Rekognition"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alarm_error_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    StreamProcessorName = "${local.name_prefix}${each.key}"
  }

  alarm_actions = var.alarm_sns_arns
  ok_actions    = var.alarm_sns_arns

  tags = merge(local.tags, each.value.tags)
}

# Alarm tracking total invocations that result in throttles, giving early
# warning of capacity issues across ALL stream processors in this module.
resource "aws_cloudwatch_metric_alarm" "stream_processor_throttles" {
  for_each = var.create_alarms ? local.active_stream_processors : {}

  alarm_name          = "${local.name_prefix}rekognition-sp-throttles-${each.key}"
  alarm_description   = "Fires when Rekognition stream processor '${each.key}' is being throttled."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "ThrottledCount"
  namespace           = "AWS/Rekognition"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alarm_error_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    StreamProcessorName = "${local.name_prefix}${each.key}"
  }

  alarm_actions = var.alarm_sns_arns
  ok_actions    = var.alarm_sns_arns

  tags = merge(local.tags, each.value.tags)
}
