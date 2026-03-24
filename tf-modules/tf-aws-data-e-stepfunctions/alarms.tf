# ── CloudWatch Alarms for Step Functions ─────────────────────────────────────
# Gated by create_alarms = true

locals {
  standard_machines = var.create_alarms ? {
    for k, v in var.state_machines : k => v
    if v.type == "STANDARD"
  } : {}

  express_machines = var.create_alarms ? {
    for k, v in var.state_machines : k => v
    if v.type == "EXPRESS"
  } : {}
}

# ── STANDARD: ExecutionsFailed ────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "sfn_executions_failed" {
  for_each = local.standard_machines

  alarm_name          = "${var.name_prefix}${each.key}-executions-failed"
  alarm_description   = "Step Functions state machine ${each.key} has failed executions."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.this[each.key].arn
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}

# ── STANDARD: ExecutionsTimedOut ──────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "sfn_executions_timed_out" {
  for_each = local.standard_machines

  alarm_name          = "${var.name_prefix}${each.key}-executions-timed-out"
  alarm_description   = "Step Functions state machine ${each.key} has timed-out executions."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsTimedOut"
  namespace           = "AWS/States"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.this[each.key].arn
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}

# ── STANDARD: ExecutionsAborted ───────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "sfn_executions_aborted" {
  for_each = local.standard_machines

  alarm_name          = "${var.name_prefix}${each.key}-executions-aborted"
  alarm_description   = "Step Functions state machine ${each.key} has aborted executions."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsAborted"
  namespace           = "AWS/States"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.this[each.key].arn
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}

# ── STANDARD: ExecutionThrottled ──────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "sfn_execution_throttled" {
  for_each = local.standard_machines

  alarm_name          = "${var.name_prefix}${each.key}-execution-throttled"
  alarm_description   = "Step Functions state machine ${each.key} has throttled executions."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionThrottled"
  namespace           = "AWS/States"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.this[each.key].arn
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}

# ── STANDARD: ExecutionTime p99 ───────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "sfn_execution_time" {
  for_each = local.standard_machines

  alarm_name          = "${var.name_prefix}${each.key}-execution-time-p99"
  alarm_description   = "Step Functions state machine ${each.key} p99 execution time exceeds threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = var.alarm_execution_time_threshold_ms
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "p99_time"
    label       = "ExecutionTime P99"
    return_data = true
    metric {
      metric_name = "ExecutionTime"
      namespace   = "AWS/States"
      period      = 300
      stat        = "p99"
      dimensions = {
        StateMachineArn = aws_sfn_state_machine.this[each.key].arn
      }
    }
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}

# ── EXPRESS: ExecutionsFailed rate ────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "sfn_express_failed_rate" {
  for_each = local.express_machines

  alarm_name          = "${var.name_prefix}${each.key}-express-failed-rate"
  alarm_description   = "EXPRESS state machine ${each.key} failure rate exceeds threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = var.alarm_express_failure_rate_threshold
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "failed"
    return_data = false
    metric {
      metric_name = "ExecutionsFailed"
      namespace   = "AWS/States"
      period      = 60
      stat        = "Sum"
      dimensions = {
        StateMachineArn = aws_sfn_state_machine.this[each.key].arn
      }
    }
  }

  metric_query {
    id          = "started"
    return_data = false
    metric {
      metric_name = "ExecutionsStarted"
      namespace   = "AWS/States"
      period      = 60
      stat        = "Sum"
      dimensions = {
        StateMachineArn = aws_sfn_state_machine.this[each.key].arn
      }
    }
  }

  metric_query {
    id          = "failure_rate"
    label       = "Failure Rate %"
    return_data = true
    expression  = "IF(started > 0, (failed / started) * 100, 0)"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}

# ── EXPRESS: ExecutionsTimedOut rate ──────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "sfn_express_timeout_rate" {
  for_each = local.express_machines

  alarm_name          = "${var.name_prefix}${each.key}-express-timeout-rate"
  alarm_description   = "EXPRESS state machine ${each.key} timeout rate exceeds threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = var.alarm_express_timeout_rate_threshold
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "timedout"
    return_data = false
    metric {
      metric_name = "ExecutionsTimedOut"
      namespace   = "AWS/States"
      period      = 60
      stat        = "Sum"
      dimensions = {
        StateMachineArn = aws_sfn_state_machine.this[each.key].arn
      }
    }
  }

  metric_query {
    id          = "started"
    return_data = false
    metric {
      metric_name = "ExecutionsStarted"
      namespace   = "AWS/States"
      period      = 60
      stat        = "Sum"
      dimensions = {
        StateMachineArn = aws_sfn_state_machine.this[each.key].arn
      }
    }
  }

  metric_query {
    id          = "timeout_rate"
    label       = "Timeout Rate %"
    return_data = true
    expression  = "IF(started > 0, (timedout / started) * 100, 0)"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}
