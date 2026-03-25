resource "aws_cloudwatch_metric_alarm" "failed_invocations" {
  for_each = var.create_alarms ? var.rules : {}

  alarm_name          = "${each.key}-failed-invocations"
  alarm_description   = "EventBridge rule ${each.key} has failed invocations."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "FailedInvocations"
  namespace           = "AWS/Events"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alarm_failed_invocations_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    RuleName = aws_cloudwatch_event_rule.this[each.key].name
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = var.tags

  depends_on = [aws_cloudwatch_event_rule.this]
}

resource "aws_cloudwatch_metric_alarm" "throttled_rules" {
  for_each = var.create_alarms ? var.rules : {}

  alarm_name          = "${each.key}-throttled-rules"
  alarm_description   = "EventBridge rule ${each.key} is being throttled."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "ThrottledRules"
  namespace           = "AWS/Events"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alarm_throttled_rules_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    RuleName = aws_cloudwatch_event_rule.this[each.key].name
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = var.tags

  depends_on = [aws_cloudwatch_event_rule.this]
}

resource "aws_cloudwatch_metric_alarm" "dead_letter_invocations" {
  for_each = var.create_alarms ? var.rules : {}

  alarm_name          = "${each.key}-dead-letter-invocations"
  alarm_description   = "EventBridge rule ${each.key} has dead-letter queue invocations."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "DeadLetterInvocations"
  namespace           = "AWS/Events"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alarm_dead_letter_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    RuleName = aws_cloudwatch_event_rule.this[each.key].name
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = var.tags

  depends_on = [aws_cloudwatch_event_rule.this]
}

resource "aws_cloudwatch_metric_alarm" "matched_events_zero" {
  for_each = var.create_alarms ? { for k, v in var.rules : k => v if v.event_pattern != null } : {}

  alarm_name          = "${each.key}-no-matched-events"
  alarm_description   = "EventBridge rule ${each.key} matched zero events — pipeline may have stalled."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "MatchedEvents"
  namespace           = "AWS/Events"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "breaching"

  dimensions = {
    RuleName = aws_cloudwatch_event_rule.this[each.key].name
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = var.tags

  depends_on = [aws_cloudwatch_event_rule.this]
}
