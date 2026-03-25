###############################################################################
# CloudWatch Alarms for AWS Batch Job Queues
###############################################################################

locals {
  alarm_queues = var.create_alarms ? {
    for k, v in aws_batch_job_queue.this : k => v.name
  } : {}

  pending_job_threshold = try(var.alarm_thresholds.pending_job_count_max, 100)
  failed_job_threshold  = try(var.alarm_thresholds.failed_job_count_max, 10)
}

resource "aws_cloudwatch_metric_alarm" "pending_jobs" {
  for_each = local.alarm_queues

  alarm_name          = "batch-${each.key}-pending-jobs-high"
  alarm_description   = "AWS Batch queue ${each.key} has more than ${local.pending_job_threshold} pending jobs."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "PendingJobCount"
  namespace           = "AWS/Batch"
  period              = 300
  statistic           = "Maximum"
  threshold           = local.pending_job_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    JobQueue = each.value
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { QueueKey = each.key })
}

resource "aws_cloudwatch_metric_alarm" "runnable_jobs_zero" {
  for_each = local.alarm_queues

  alarm_name          = "batch-${each.key}-no-runnable-capacity"
  alarm_description   = "AWS Batch queue ${each.key} has pending jobs but zero runnable (compute environment may be saturated or unavailable)."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "RunnableJobCount"
  namespace           = "AWS/Batch"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    JobQueue = each.value
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { QueueKey = each.key })
}

resource "aws_cloudwatch_metric_alarm" "failed_jobs" {
  for_each = local.alarm_queues

  alarm_name          = "batch-${each.key}-failed-jobs-high"
  alarm_description   = "AWS Batch queue ${each.key} has more than ${local.failed_job_threshold} failed jobs in the past 5 minutes."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedJobCount"
  namespace           = "AWS/Batch"
  period              = 300
  statistic           = "Sum"
  threshold           = local.failed_job_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    JobQueue = each.value
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { QueueKey = each.key })
}

resource "aws_cloudwatch_metric_alarm" "succeeded_jobs_rate" {
  for_each = local.alarm_queues

  alarm_name          = "batch-${each.key}-succeeded-jobs-monitoring"
  alarm_description   = "AWS Batch queue ${each.key} succeeded job rate monitoring — alert if zero successes over extended period."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 12
  metric_name         = "SucceededJobCount"
  namespace           = "AWS/Batch"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    JobQueue = each.value
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { QueueKey = each.key })
}
