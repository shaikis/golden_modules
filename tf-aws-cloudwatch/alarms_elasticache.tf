# =============================================================================
# tf-aws-cloudwatch — ElastiCache (Redis / Memcached) Alarms
#
# Creates per-cluster alarms:
#   - CPU Engine utilization high
#   - Freeable memory low         → risk of evictions
#   - Evictions high              → cache is full, hot data being evicted
#   - Connections high            → connection pool exhaustion risk
#   - Replication lag high        → replica is behind primary (Redis replication)
#
# To disable: set elasticache_alarms = {}
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "elasticache_alarms" {
  description = <<-EOT
    Map of ElastiCache cluster alarm configurations (Redis or Memcached).
    Key = logical name. cache_cluster_id is the actual ElastiCache cluster ID.

    Example:
      prod_cache = {
        cache_cluster_id        = "prod-myapp-redis"
        cpu_threshold           = 80
        evictions_threshold     = 100
        freeable_memory_bytes   = 536870912  # 512 MB
        create_replication_alarm = true
        replication_lag_seconds = 5
      }
  EOT
  type = map(object({
    cache_cluster_id         = string
    cpu_threshold            = optional(number, 80)
    evictions_threshold      = optional(number, 100)
    freeable_memory_bytes    = optional(number, 536870912) # 512 MB
    connections_threshold    = optional(number, null)
    replication_lag_seconds  = optional(number, 5)
    evaluation_periods       = optional(number, 2)
    period                   = optional(number, 300)
    create_cpu_alarm         = optional(bool, true)
    create_evictions_alarm   = optional(bool, true)
    create_memory_alarm      = optional(bool, true)
    create_connections_alarm = optional(bool, false)
    create_replication_alarm = optional(bool, false)
  }))
  default = {}
}

# ── CPU Engine Utilization ────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "elasticache_cpu" {
  for_each = { for k, v in var.elasticache_alarms : k => v if v.create_cpu_alarm }

  alarm_name          = "${local.prefix}-elasticache-${each.key}-cpu-high"
  alarm_description   = "ElastiCache ${each.value.cache_cluster_id}: CPU above ${each.value.cpu_threshold}%. Redis is single-threaded — high CPU means cache is under heavy load."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = each.value.period
  statistic           = "Average"
  threshold           = each.value.cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = each.value.cache_cluster_id
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Component = "elasticache" })
}

# ── Evictions High ────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "elasticache_evictions" {
  for_each = { for k, v in var.elasticache_alarms : k => v if v.create_evictions_alarm }

  alarm_name          = "${local.prefix}-elasticache-${each.key}-evictions-high"
  alarm_description   = "ElastiCache ${each.value.cache_cluster_id}: evictions above ${each.value.evictions_threshold}. Cache is full — increase memory or reduce TTLs to prevent cache thrashing."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = each.value.period
  statistic           = "Sum"
  threshold           = each.value.evictions_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = each.value.cache_cluster_id
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Component = "elasticache" })
}

# ── Freeable Memory Low ───────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "elasticache_memory" {
  for_each = { for k, v in var.elasticache_alarms : k => v if v.create_memory_alarm }

  alarm_name          = "${local.prefix}-elasticache-${each.key}-memory-low"
  alarm_description   = "ElastiCache ${each.value.cache_cluster_id}: freeable memory below ${each.value.freeable_memory_bytes / 1048576} MB. Evictions will increase — consider upgrading node type."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "FreeableMemory"
  namespace           = "AWS/ElastiCache"
  period              = each.value.period
  statistic           = "Average"
  threshold           = each.value.freeable_memory_bytes
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = each.value.cache_cluster_id
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "elasticache" })
}

# ── Current Connections High ──────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "elasticache_connections" {
  for_each = { for k, v in var.elasticache_alarms : k => v if v.create_connections_alarm && v.connections_threshold != null }

  alarm_name          = "${local.prefix}-elasticache-${each.key}-connections-high"
  alarm_description   = "ElastiCache ${each.value.cache_cluster_id}: connections above ${each.value.connections_threshold}. Risk of connection pool exhaustion in application tier."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = each.value.period
  statistic           = "Maximum"
  threshold           = each.value.connections_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = each.value.cache_cluster_id
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Component = "elasticache" })
}

# ── Replication Lag (Redis only) ──────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "elasticache_replication_lag" {
  for_each = { for k, v in var.elasticache_alarms : k => v if v.create_replication_alarm }

  alarm_name          = "${local.prefix}-elasticache-${each.key}-replication-lag"
  alarm_description   = "ElastiCache Redis ${each.value.cache_cluster_id}: replication lag exceeds ${each.value.replication_lag_seconds}s. Read replicas are serving stale data — failover may return old values."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "ReplicationLag"
  namespace           = "AWS/ElastiCache"
  period              = each.value.period
  statistic           = "Maximum"
  threshold           = each.value.replication_lag_seconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = each.value.cache_cluster_id
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Component = "elasticache" })
}
