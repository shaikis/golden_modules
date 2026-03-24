# ---------------------------------------------------------------------------
# CloudWatch Alarms — Kinesis Data Streams + Firehose
# ---------------------------------------------------------------------------

locals {
  alarms_enabled = var.create_alarms

  # Collect all firehose ARNs for alarm targeting
  all_firehose_names = merge(
    { for k, v in aws_kinesis_firehose_delivery_stream.s3 : k => v.name },
    { for k, v in aws_kinesis_firehose_delivery_stream.redshift : k => v.name },
    { for k, v in aws_kinesis_firehose_delivery_stream.opensearch : k => v.name },
    { for k, v in aws_kinesis_firehose_delivery_stream.splunk : k => v.name },
    { for k, v in aws_kinesis_firehose_delivery_stream.http_endpoint : k => v.name },
  )
}

# ---------------------------------------------------------------------------
# Kinesis Data Stream Alarms
# ---------------------------------------------------------------------------

# Consumer iterator age — signals a consumer is falling behind
resource "aws_cloudwatch_metric_alarm" "iterator_age" {
  for_each = local.alarms_enabled ? aws_kinesis_stream.this : {}

  alarm_name          = "${each.value.name}-IteratorAge"
  alarm_description   = "Consumer iterator age exceeded ${var.iterator_age_threshold_ms}ms on stream ${each.value.name}. Consumer may be falling behind."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = var.alarm_period_seconds
  statistic           = "Maximum"
  threshold           = var.iterator_age_threshold_ms
  treat_missing_data  = "notBreaching"

  dimensions = {
    StreamName = each.value.name
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${each.value.name}-IteratorAge"
    ManagedBy = "terraform"
  })
}

# Write throttling — provisioned throughput exceeded on writes
resource "aws_cloudwatch_metric_alarm" "write_throttle" {
  for_each = local.alarms_enabled ? aws_kinesis_stream.this : {}

  alarm_name          = "${each.value.name}-WriteThrottle"
  alarm_description   = "Write provisioned throughput exceeded on stream ${each.value.name}. Consider increasing shards."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "WriteProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    StreamName = each.value.name
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${each.value.name}-WriteThrottle"
    ManagedBy = "terraform"
  })
}

# Read throttling — provisioned throughput exceeded on reads
resource "aws_cloudwatch_metric_alarm" "read_throttle" {
  for_each = local.alarms_enabled ? aws_kinesis_stream.this : {}

  alarm_name          = "${each.value.name}-ReadThrottle"
  alarm_description   = "Read provisioned throughput exceeded on stream ${each.value.name}. Consider adding enhanced fan-out consumers."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "ReadProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    StreamName = each.value.name
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${each.value.name}-ReadThrottle"
    ManagedBy = "terraform"
  })
}

# PutRecords failed records — partial batch failures
resource "aws_cloudwatch_metric_alarm" "put_records_failed" {
  for_each = local.alarms_enabled ? aws_kinesis_stream.this : {}

  alarm_name          = "${each.value.name}-PutRecordsFailed"
  alarm_description   = "PutRecords.FailedRecords exceeded threshold on stream ${each.value.name}. Check producer error handling."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "PutRecords.FailedRecords"
  namespace           = "AWS/Kinesis"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.put_records_failed_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    StreamName = each.value.name
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${each.value.name}-PutRecordsFailed"
    ManagedBy = "terraform"
  })
}

# ---------------------------------------------------------------------------
# Firehose Alarms
# ---------------------------------------------------------------------------

# Data freshness (delivery lag) — triggers when records are buffered too long
resource "aws_cloudwatch_metric_alarm" "firehose_freshness" {
  for_each = local.alarms_enabled ? local.all_firehose_names : {}

  alarm_name          = "${each.value}-DataFreshness"
  alarm_description   = "Firehose ${each.value} delivery freshness exceeded ${var.firehose_freshness_threshold_seconds}s. Delivery to S3 may be delayed."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "DeliveryToS3.DataFreshness"
  namespace           = "AWS/Firehose"
  period              = var.alarm_period_seconds
  statistic           = "Maximum"
  threshold           = var.firehose_freshness_threshold_seconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    DeliveryStreamName = each.value
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${each.value}-DataFreshness"
    ManagedBy = "terraform"
  })
}

# Delivery success rate below threshold
resource "aws_cloudwatch_metric_alarm" "firehose_delivery_success" {
  for_each = local.alarms_enabled ? local.all_firehose_names : {}

  alarm_name          = "${each.value}-DeliverySuccess"
  alarm_description   = "Firehose ${each.value} S3 delivery success rate is below ${var.firehose_success_threshold * 100}%."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "DeliveryToS3.Success"
  namespace           = "AWS/Firehose"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.firehose_success_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    DeliveryStreamName = each.value
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${each.value}-DeliverySuccess"
    ManagedBy = "terraform"
  })
}

# Throttled records
resource "aws_cloudwatch_metric_alarm" "firehose_throttled" {
  for_each = local.alarms_enabled ? local.all_firehose_names : {}

  alarm_name          = "${each.value}-ThrottledRecords"
  alarm_description   = "Firehose ${each.value} has throttled records. Kinesis source stream may be over-read."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "ThrottledRecords"
  namespace           = "AWS/Firehose"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    DeliveryStreamName = each.value
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${each.value}-ThrottledRecords"
    ManagedBy = "terraform"
  })
}
