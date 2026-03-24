locals {
  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  # Flatten cluster alarms into a single map
  cluster_alarm_definitions = var.create_alarms ? merge(
    # HealthStatus alarms
    {
      for k, v in var.clusters :
      "${k}__health_status" => {
        cluster_key         = k
        alarm_name          = "${k}-health-status"
        metric_name         = "HealthStatus"
        comparison_operator = "LessThanThreshold"
        threshold           = 1
        statistic           = "Average"
        description         = "Redshift cluster ${k} health status is degraded"
        dimensions          = { ClusterIdentifier = k }
      }
    },
    # CPUUtilization alarms
    {
      for k, v in var.clusters :
      "${k}__cpu" => {
        cluster_key         = k
        alarm_name          = "${k}-cpu-utilization"
        metric_name         = "CPUUtilization"
        comparison_operator = "GreaterThanThreshold"
        threshold           = var.alarm_cpu_threshold
        statistic           = "Average"
        description         = "Redshift cluster ${k} CPU utilization exceeds ${var.alarm_cpu_threshold}%"
        dimensions          = { ClusterIdentifier = k }
      }
    },
    # DatabaseConnections alarms
    {
      for k, v in var.clusters :
      "${k}__connections" => {
        cluster_key         = k
        alarm_name          = "${k}-database-connections"
        metric_name         = "DatabaseConnections"
        comparison_operator = "GreaterThanThreshold"
        threshold           = var.alarm_connections_threshold
        statistic           = "Average"
        description         = "Redshift cluster ${k} database connections exceed ${var.alarm_connections_threshold}"
        dimensions          = { ClusterIdentifier = k }
      }
    },
    # DiskSpaceUsedPercent alarms
    {
      for k, v in var.clusters :
      "${k}__disk" => {
        cluster_key         = k
        alarm_name          = "${k}-disk-space-used"
        metric_name         = "PercentageDiskSpaceUsed"
        comparison_operator = "GreaterThanThreshold"
        threshold           = var.alarm_disk_threshold
        statistic           = "Average"
        description         = "Redshift cluster ${k} disk usage exceeds ${var.alarm_disk_threshold}%"
        dimensions          = { ClusterIdentifier = k }
      }
    },
    # ReadLatency alarms
    {
      for k, v in var.clusters :
      "${k}__read_latency" => {
        cluster_key         = k
        alarm_name          = "${k}-read-latency"
        metric_name         = "ReadLatency"
        comparison_operator = "GreaterThanThreshold"
        threshold           = var.alarm_read_latency_threshold
        statistic           = "Average"
        description         = "Redshift cluster ${k} read latency exceeds ${var.alarm_read_latency_threshold}s"
        dimensions          = { ClusterIdentifier = k }
      }
    },
    # WriteLatency alarms
    {
      for k, v in var.clusters :
      "${k}__write_latency" => {
        cluster_key         = k
        alarm_name          = "${k}-write-latency"
        metric_name         = "WriteLatency"
        comparison_operator = "GreaterThanThreshold"
        threshold           = var.alarm_write_latency_threshold
        statistic           = "Average"
        description         = "Redshift cluster ${k} write latency exceeds ${var.alarm_write_latency_threshold}s"
        dimensions          = { ClusterIdentifier = k }
      }
    },
    # MaintenanceModeEnabled alarms
    {
      for k, v in var.clusters :
      "${k}__maintenance" => {
        cluster_key         = k
        alarm_name          = "${k}-maintenance-mode"
        metric_name         = "MaintenanceModeEnabled"
        comparison_operator = "GreaterThanOrEqualToThreshold"
        threshold           = 1
        statistic           = "Maximum"
        description         = "Redshift cluster ${k} is in maintenance mode"
        dimensions          = { ClusterIdentifier = k }
      }
    }
  ) : {}
}

resource "aws_cloudwatch_metric_alarm" "cluster" {
  for_each = local.cluster_alarm_definitions

  alarm_name          = each.value.alarm_name
  alarm_description   = each.value.description
  comparison_operator = each.value.comparison_operator
  metric_name         = each.value.metric_name
  namespace           = "AWS/Redshift"
  period              = var.alarm_period_seconds
  evaluation_periods  = var.alarm_evaluation_periods
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  dimensions          = each.value.dimensions

  tags = merge(var.tags, {
    Name = each.value.alarm_name
  })
}

# Serverless ComputeSeconds alarms
resource "aws_cloudwatch_metric_alarm" "serverless" {
  for_each = var.create_alarms && var.create_serverless ? var.serverless_workgroups : {}

  alarm_name          = "${each.key}-compute-seconds"
  alarm_description   = "Redshift Serverless workgroup ${each.key} compute seconds exceeds cost threshold"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "ComputeSeconds"
  namespace           = "AWS/Redshift-Serverless"
  period              = var.alarm_period_seconds
  evaluation_periods  = var.alarm_evaluation_periods
  statistic           = "Sum"
  threshold           = var.alarm_compute_seconds_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    WorkgroupName = each.key
  }

  tags = merge(var.tags, {
    Name = "${each.key}-compute-seconds"
  })
}
