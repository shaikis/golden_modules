# =============================================================================
# tf-aws-cloudwatch — RDS / Aurora Instance Alarms
#
# Creates per-instance alarms (enabled individually via flags per entry):
#   - CPU Utilization high
#   - Freeable Memory low
#   - Free Storage Space low
#   - Database Connections high
#   - Read/Write IOPS high (optional)
#   - Replica Lag high (optional — for read replicas and Aurora clusters)
#
# To disable all RDS alarms: set rds_alarms = {}
# To disable one alarm type for a specific instance: set create_xxx_alarm = false
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "rds_alarms" {
  description = <<-EOT
    Map of RDS instance alarm configurations.
    Key = logical name. Use db_instance_id for the actual AWS RDS identifier.

    Example:
      prod_db = {
        db_instance_id        = "prod-myapp-postgres"
        cpu_threshold         = 80
        connections_threshold = 200
        free_storage_bytes    = 10737418240   # 10 GB
        replica_lag_seconds   = 30
        create_replica_lag_alarm = true
      }
  EOT
  type = map(object({
    db_instance_id           = string
    cpu_threshold            = optional(number, 80)
    connections_threshold    = optional(number, null)
    free_storage_bytes       = optional(number, 10737418240) # 10 GB
    freeable_memory_bytes    = optional(number, 268435456)   # 256 MB
    replica_lag_seconds      = optional(number, 30)
    read_iops_threshold      = optional(number, null)
    write_iops_threshold     = optional(number, null)
    evaluation_periods       = optional(number, 2)
    period                   = optional(number, 300)
    create_cpu_alarm         = optional(bool, true)
    create_storage_alarm     = optional(bool, true)
    create_connections_alarm = optional(bool, false)
    create_replica_lag_alarm = optional(bool, false)
    create_memory_alarm      = optional(bool, true)
    create_iops_alarm        = optional(bool, false)
  }))
  default = {}
}

# ── CPU Utilization ───────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  for_each = { for k, v in var.rds_alarms : k => v if v.create_cpu_alarm }

  alarm_name          = "${local.prefix}-rds-${each.key}-cpu-high"
  alarm_description   = "RDS ${each.value.db_instance_id}: CPU above ${each.value.cpu_threshold}%. Check for slow queries, missing indexes, or high connection count."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = each.value.period
  statistic           = "Average"
  threshold           = each.value.cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = each.value.db_instance_id
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "rds" })
}

# ── Freeable Memory Low ───────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "rds_memory" {
  for_each = { for k, v in var.rds_alarms : k => v if v.create_memory_alarm }

  alarm_name          = "${local.prefix}-rds-${each.key}-memory-low"
  alarm_description   = "RDS ${each.value.db_instance_id}: freeable memory is low (< ${each.value.freeable_memory_bytes / 1048576} MB). Risk of OOM swap or instance instability."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = each.value.period
  statistic           = "Average"
  threshold           = each.value.freeable_memory_bytes
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = each.value.db_instance_id
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "rds" })
}

# ── Free Storage Space Low ────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  for_each = { for k, v in var.rds_alarms : k => v if v.create_storage_alarm }

  alarm_name          = "${local.prefix}-rds-${each.key}-storage-low"
  alarm_description   = "RDS ${each.value.db_instance_id}: free storage below ${each.value.free_storage_bytes / 1073741824} GB. Database will stop accepting writes when storage runs out."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = each.value.period
  statistic           = "Average"
  threshold           = each.value.free_storage_bytes
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = each.value.db_instance_id
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "rds" })
}

# ── Database Connections High ─────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  for_each = { for k, v in var.rds_alarms : k => v if v.create_connections_alarm && v.connections_threshold != null }

  alarm_name          = "${local.prefix}-rds-${each.key}-connections-high"
  alarm_description   = "RDS ${each.value.db_instance_id}: connection count exceeds ${each.value.connections_threshold}. Risk of 'too many connections' errors for applications."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = each.value.period
  statistic           = "Average"
  threshold           = each.value.connections_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = each.value.db_instance_id
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Component = "rds" })
}

# ── Replica Lag ───────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "rds_replica_lag" {
  for_each = { for k, v in var.rds_alarms : k => v if v.create_replica_lag_alarm }

  alarm_name          = "${local.prefix}-rds-${each.key}-replica-lag"
  alarm_description   = "RDS ${each.value.db_instance_id}: replica lag exceeds ${each.value.replica_lag_seconds}s. Read replicas are serving stale data."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = each.value.period
  statistic           = "Average"
  threshold           = each.value.replica_lag_seconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = each.value.db_instance_id
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Component = "rds" })
}

# ── Read IOPS High ────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "rds_read_iops" {
  for_each = { for k, v in var.rds_alarms : k => v if v.create_iops_alarm && v.read_iops_threshold != null }

  alarm_name          = "${local.prefix}-rds-${each.key}-read-iops-high"
  alarm_description   = "RDS ${each.value.db_instance_id}: read IOPS exceeds ${each.value.read_iops_threshold}. Check for full table scans or missing indexes."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "ReadIOPS"
  namespace           = "AWS/RDS"
  period              = each.value.period
  statistic           = "Average"
  threshold           = each.value.read_iops_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = each.value.db_instance_id
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Component = "rds" })
}
