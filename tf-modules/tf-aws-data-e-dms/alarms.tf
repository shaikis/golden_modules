locals {
  # Build flat map of task_id -> task for alarm iteration
  alarm_tasks = var.create_alarms ? {
    for k, v in aws_dms_replication_task.this : k => v.replication_task_id
  } : {}
}

# ---------------------------------------------------------------------------
# CDC source latency — measures how far behind the source replication is
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cdc_latency_source" {
  for_each = local.alarm_tasks

  alarm_name          = "${each.value}-CDCLatencySource"
  alarm_description   = "DMS task ${each.value} CDC source latency exceeded ${var.alarm_cdc_latency_source_threshold}s."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CDCLatencySource"
  namespace           = "AWS/DMS"
  period              = var.alarm_period_seconds
  statistic           = "Maximum"
  threshold           = var.alarm_cdc_latency_source_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions          = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    ReplicationInstanceIdentifier = each.value
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# CDC target latency — measures how far behind the target apply is
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cdc_latency_target" {
  for_each = local.alarm_tasks

  alarm_name          = "${each.value}-CDCLatencyTarget"
  alarm_description   = "DMS task ${each.value} CDC target latency exceeded ${var.alarm_cdc_latency_target_threshold}s."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CDCLatencyTarget"
  namespace           = "AWS/DMS"
  period              = var.alarm_period_seconds
  statistic           = "Maximum"
  threshold           = var.alarm_cdc_latency_target_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions          = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    ReplicationInstanceIdentifier = each.value
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# CDC incoming changes — rate of changes arriving from source
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cdc_incoming_changes" {
  for_each = local.alarm_tasks

  alarm_name          = "${each.value}-CDCIncomingChangesHigh"
  alarm_description   = "DMS task ${each.value} has a very high rate of incoming CDC changes. Verify replication instance capacity."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CDCIncomingChanges"
  namespace           = "AWS/DMS"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = 100000
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions          = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    ReplicationInstanceIdentifier = each.value
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Full load throughput rows (target) — rows loaded per second to target
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "full_load_throughput_rows_target" {
  for_each = local.alarm_tasks

  alarm_name          = "${each.value}-FullLoadThroughputRowsTargetLow"
  alarm_description   = "DMS task ${each.value} full-load target throughput is very low. Migration may be stalled."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "FullLoadThroughputRowsTarget"
  namespace           = "AWS/DMS"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions          = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    ReplicationInstanceIdentifier = each.value
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Table errors — any table-level error triggers this alarm immediately
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "table_errors" {
  for_each = local.alarm_tasks

  alarm_name          = "${each.value}-TableErrors"
  alarm_description   = "DMS task ${each.value} has encountered table-level errors. Check DMS task logs."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TableErrors"
  namespace           = "AWS/DMS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions          = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    ReplicationInstanceIdentifier = each.value
  }

  tags = var.tags
}
