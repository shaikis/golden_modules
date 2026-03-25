# ---------------------------------------------------------------------------
# CloudWatch Alarms — DataSync Tasks
# Gated by create_alarms = true
# ---------------------------------------------------------------------------

locals {
  task_alarm_map = var.create_alarms ? var.tasks : {}
}

# ── Bytes Transferred ─────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "bytes_transferred" {
  for_each = local.task_alarm_map

  alarm_name          = "${each.key}-bytes-transferred-low"
  alarm_description   = "DataSync task ${each.key} transferred zero bytes in the last period."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "BytesTransferred"
  namespace           = "AWS/DataSync"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    TaskId = aws_datasync_task.this[each.key].id
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { Name = "${each.key}-bytes-transferred-low" })
}

# ── Files Verified Failed ─────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "files_verified_failed" {
  for_each = local.task_alarm_map

  alarm_name          = "${each.key}-files-verified-failed"
  alarm_description   = "DataSync task ${each.key} has file verification failures."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "FilesVerifiedFailed"
  namespace           = "AWS/DataSync"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    TaskId = aws_datasync_task.this[each.key].id
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { Name = "${each.key}-files-verified-failed" })
}

# ── Task Execution Errors ────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "task_execution_errors" {
  for_each = local.task_alarm_map

  alarm_name          = "${each.key}-execution-errors"
  alarm_description   = "DataSync task ${each.key} has task execution errors."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "TaskExecutionErrors"
  namespace           = "AWS/DataSync"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    TaskId = aws_datasync_task.this[each.key].id
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { Name = "${each.key}-execution-errors" })
}

# ── Files Prepared vs Transferred Gap ─────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "files_not_transferred" {
  for_each = local.task_alarm_map

  alarm_name          = "${each.key}-files-not-transferred"
  alarm_description   = "DataSync task ${each.key}: FilesPrepared exceeds FilesTransferred indicating stuck transfer."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  threshold           = 0
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "prepared"
    return_data = false

    metric {
      metric_name = "FilesPrepared"
      namespace   = "AWS/DataSync"
      period      = var.alarm_period_seconds
      stat        = "Sum"

      dimensions = {
        TaskId = aws_datasync_task.this[each.key].id
      }
    }
  }

  metric_query {
    id          = "transferred"
    return_data = false

    metric {
      metric_name = "FilesTransferred"
      namespace   = "AWS/DataSync"
      period      = var.alarm_period_seconds
      stat        = "Sum"

      dimensions = {
        TaskId = aws_datasync_task.this[each.key].id
      }
    }
  }

  metric_query {
    id          = "gap"
    expression  = "prepared - transferred"
    label       = "Files Not Yet Transferred"
    return_data = true
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { Name = "${each.key}-files-not-transferred" })
}
