###############################################################################
# CloudWatch Alarms for EMR Clusters
###############################################################################

locals {
  alarm_cluster_ids = var.create_alarms ? {
    for k, v in aws_emr_cluster.this : k => v.id
  } : {}

  hdfs_threshold        = try(var.alarm_thresholds.hdfs_utilization_percent, 80)
  live_nodes_min        = try(var.alarm_thresholds.live_data_nodes_min, 1)
  core_nodes_min        = try(var.alarm_thresholds.core_nodes_min, 1)
  capacity_remaining_gb = try(var.alarm_thresholds.capacity_remaining_gb_min, 100)
}

resource "aws_cloudwatch_metric_alarm" "hdfs_utilization" {
  for_each = local.alarm_cluster_ids

  alarm_name          = "emr-${each.key}-hdfs-utilization-high"
  alarm_description   = "EMR cluster ${each.key} HDFS utilization exceeds ${local.hdfs_threshold}%."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HDFSUtilization"
  namespace           = "AWS/ElasticMapReduce"
  period              = 300
  statistic           = "Average"
  threshold           = local.hdfs_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    JobFlowId = each.value
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { ClusterKey = each.key })
}

resource "aws_cloudwatch_metric_alarm" "cluster_idle" {
  for_each = local.alarm_cluster_ids

  alarm_name          = "emr-${each.key}-cluster-idle"
  alarm_description   = "EMR cluster ${each.key} has been idle (no jobs running). Potential cost waste."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "IsIdle"
  namespace           = "AWS/ElasticMapReduce"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    JobFlowId = each.value
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { ClusterKey = each.key })
}

resource "aws_cloudwatch_metric_alarm" "core_nodes_running" {
  for_each = local.alarm_cluster_ids

  alarm_name          = "emr-${each.key}-core-nodes-low"
  alarm_description   = "EMR cluster ${each.key} has fewer core nodes than expected minimum of ${local.core_nodes_min}."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CoreNodesRunning"
  namespace           = "AWS/ElasticMapReduce"
  period              = 300
  statistic           = "Average"
  threshold           = local.core_nodes_min
  treat_missing_data  = "breaching"

  dimensions = {
    JobFlowId = each.value
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { ClusterKey = each.key })
}

resource "aws_cloudwatch_metric_alarm" "live_data_nodes" {
  for_each = local.alarm_cluster_ids

  alarm_name          = "emr-${each.key}-live-data-nodes-low"
  alarm_description   = "EMR cluster ${each.key} live data nodes dropped below ${local.live_nodes_min}. HDFS risk."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "LiveDataNodes"
  namespace           = "AWS/ElasticMapReduce"
  period              = 300
  statistic           = "Average"
  threshold           = local.live_nodes_min
  treat_missing_data  = "breaching"

  dimensions = {
    JobFlowId = each.value
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { ClusterKey = each.key })
}

resource "aws_cloudwatch_metric_alarm" "capacity_remaining" {
  for_each = local.alarm_cluster_ids

  alarm_name          = "emr-${each.key}-capacity-remaining-low"
  alarm_description   = "EMR cluster ${each.key} HDFS remaining capacity below ${local.capacity_remaining_gb} GB."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CapacityRemainingGB"
  namespace           = "AWS/ElasticMapReduce"
  period              = 300
  statistic           = "Average"
  threshold           = local.capacity_remaining_gb
  treat_missing_data  = "notBreaching"

  dimensions = {
    JobFlowId = each.value
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { ClusterKey = each.key })
}

resource "aws_cloudwatch_metric_alarm" "mr_input_bytes" {
  for_each = local.alarm_cluster_ids

  alarm_name          = "emr-${each.key}-mr-input-throughput"
  alarm_description   = "EMR cluster ${each.key} MapReduce input bytes monitoring."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MRTotalInputBytes"
  namespace           = "AWS/ElasticMapReduce"
  period              = 3600
  statistic           = "Sum"
  threshold           = 1099511627776 # 1 TB
  treat_missing_data  = "notBreaching"

  dimensions = {
    JobFlowId = each.value
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { ClusterKey = each.key })
}
