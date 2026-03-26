# ──────────────────────────────────────────────────────────────────────────────
# CloudWatch Alarms — Textract async job monitoring via SQS queue metrics
# Requires create_alarms = true AND create_sqs_queues = true with queues defined
# ──────────────────────────────────────────────────────────────────────────────

locals {
  # Only create alarms for queues that exist when both feature flags are on
  alarm_queue_keys = (var.create_alarms && var.create_sqs_queues) ? keys(var.sqs_queues) : []

  # Only create DLQ alarms for queues that opted-in to DLQ creation
  alarm_dlq_keys = (var.create_alarms && var.create_sqs_queues) ? [
    for k, v in var.sqs_queues : k if v.create_dlq
  ] : []
}

# ── Queue depth alarm — Textract results waiting to be processed ──────────────

resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth" {
  for_each = toset(local.alarm_queue_keys)

  alarm_name          = "${local.name_prefix}textract-${each.key}-queue-depth"
  alarm_description   = "Textract result queue depth is high — ${each.key} has many messages waiting to be processed."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 100

  dimensions = {
    QueueName = aws_sqs_queue.textract[each.key].name
  }

  alarm_actions             = var.alarm_sns_arns
  ok_actions                = var.alarm_sns_arns
  insufficient_data_actions = []

  treat_missing_data = "notBreaching"

  tags = local.tags
}

# ── DLQ message count alarm — failed Textract result processing ───────────────

resource "aws_cloudwatch_metric_alarm" "sqs_dlq_depth" {
  for_each = toset(local.alarm_dlq_keys)

  alarm_name          = "${local.name_prefix}textract-${each.key}-dlq-depth"
  alarm_description   = "Textract DLQ has messages — ${each.key} results are failing to process after max retries."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0

  dimensions = {
    QueueName = aws_sqs_queue.textract_dlq[each.key].name
  }

  alarm_actions             = var.alarm_sns_arns
  ok_actions                = var.alarm_sns_arns
  insufficient_data_actions = []

  treat_missing_data = "notBreaching"

  tags = local.tags
}

# ── Age of oldest message alarm — stale Textract results ─────────────────────

resource "aws_cloudwatch_metric_alarm" "sqs_oldest_message_age" {
  for_each = toset(local.alarm_queue_keys)

  alarm_name          = "${local.name_prefix}textract-${each.key}-oldest-message-age"
  alarm_description   = "Oldest Textract result message in ${each.key} is over 30 minutes old — processor may be stalled."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 1800 # 30 minutes in seconds

  dimensions = {
    QueueName = aws_sqs_queue.textract[each.key].name
  }

  alarm_actions             = var.alarm_sns_arns
  ok_actions                = var.alarm_sns_arns
  insufficient_data_actions = []

  treat_missing_data = "notBreaching"

  tags = local.tags
}
