locals {
  # Build a flat map of cluster_name -> cluster_arn for alarm dimensions
  alarm_clusters = var.create_alarms ? {
    for k, v in aws_msk_cluster.this : k => v.cluster_name
  } : {}
}

# ---------------------------------------------------------------------------
# Disk usage alarm — warn before brokers run out of space
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "kafka_disk_used" {
  for_each = local.alarm_clusters

  alarm_name          = "${each.value}-KafkaAppLogsDiskUsed"
  alarm_description   = "MSK broker disk usage exceeded ${var.alarm_disk_used_percent_threshold}% on cluster ${each.value}."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "KafkaAppLogsDiskUsed"
  namespace           = "AWS/Kafka"
  period              = var.alarm_period_seconds
  statistic           = "Maximum"
  threshold           = var.alarm_disk_used_percent_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions          = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    "Cluster Name" = each.value
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Memory usage alarm
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "memory_used" {
  for_each = local.alarm_clusters

  alarm_name          = "${each.value}-MemoryUsed"
  alarm_description   = "MSK broker memory usage exceeded ${var.alarm_memory_used_percent_threshold}% on cluster ${each.value}."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "MemoryUsed"
  namespace           = "AWS/Kafka"
  period              = var.alarm_period_seconds
  statistic           = "Maximum"
  threshold           = var.alarm_memory_used_percent_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions          = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    "Cluster Name" = each.value
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# CPU user alarm
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_user" {
  for_each = local.alarm_clusters

  alarm_name          = "${each.value}-CPUUser"
  alarm_description   = "MSK broker CPU user exceeded ${var.alarm_cpu_user_threshold}% on cluster ${each.value}."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CpuUser"
  namespace           = "AWS/Kafka"
  period              = var.alarm_period_seconds
  statistic           = "Maximum"
  threshold           = var.alarm_cpu_user_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions          = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    "Cluster Name" = each.value
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Network Rx dropped packets
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "network_rx_dropped" {
  for_each = local.alarm_clusters

  alarm_name          = "${each.value}-NetworkRxDropped"
  alarm_description   = "MSK broker is dropping incoming network packets on cluster ${each.value}."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "NetworkRxDropped"
  namespace           = "AWS/Kafka"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions          = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    "Cluster Name" = each.value
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Network Tx dropped packets
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "network_tx_dropped" {
  for_each = local.alarm_clusters

  alarm_name          = "${each.value}-NetworkTxDropped"
  alarm_description   = "MSK broker is dropping outgoing network packets on cluster ${each.value}."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "NetworkTxDropped"
  namespace           = "AWS/Kafka"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions          = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    "Cluster Name" = each.value
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Under-replicated partitions — CRITICAL: data loss risk
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "under_replicated_partitions" {
  for_each = local.alarm_clusters

  alarm_name          = "${each.value}-UnderReplicatedPartitions"
  alarm_description   = "CRITICAL: Under-replicated partitions detected on MSK cluster ${each.value}. Data loss risk."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnderReplicatedPartitions"
  namespace           = "AWS/Kafka"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions          = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    "Cluster Name" = each.value
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Active controller count — CRITICAL: exactly 1 controller must be active
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "active_controller_count" {
  for_each = local.alarm_clusters

  alarm_name          = "${each.value}-ActiveControllerCount"
  alarm_description   = "CRITICAL: MSK cluster ${each.value} does not have exactly 1 active controller."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ActiveControllerCount"
  namespace           = "AWS/Kafka"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "breaching"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions          = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    "Cluster Name" = each.value
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Offline partitions — CRITICAL: partitions unavailable for reads/writes
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "offline_partitions_count" {
  for_each = local.alarm_clusters

  alarm_name          = "${each.value}-OfflinePartitionsCount"
  alarm_description   = "CRITICAL: Offline partitions detected on MSK cluster ${each.value}. Partitions are unavailable."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "OfflinePartitionsCount"
  namespace           = "AWS/Kafka"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions          = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    "Cluster Name" = each.value
  }

  tags = var.tags
}
