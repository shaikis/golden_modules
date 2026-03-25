# =============================================================================
# tf-aws-cloudwatch — ECS Cluster / Service Alarms
#
# Monitors ECS services for CPU, memory, and running task count.
# ECS Container Insights must be enabled on the cluster for these metrics to exist.
# Enable Container Insights: aws ecs update-cluster-settings --cluster <name>
#   --settings name=containerInsights,value=enabled
#
# Creates per-service alarms:
#   - CPU utilization high
#   - Memory utilization high
#   - Running task count below minimum (tasks crashed or failed to start)
#
# To disable: set ecs_alarms = {}
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "ecs_alarms" {
  description = <<-EOT
    Map of ECS service alarm configurations.
    Key = logical name. Requires Container Insights enabled on the cluster.

    Example:
      api_service = {
        cluster_name   = "prod-cluster"
        service_name   = "api-service"
        cpu_threshold  = 80
        mem_threshold  = 80
        min_task_count = 2
      }
  EOT
  type = map(object({
    cluster_name        = string
    service_name        = string
    cpu_threshold       = optional(number, 80)
    mem_threshold       = optional(number, 80)
    min_task_count      = optional(number, null)
    evaluation_periods  = optional(number, 2)
    period              = optional(number, 300)
    create_cpu_alarm    = optional(bool, true)
    create_memory_alarm = optional(bool, true)
    create_task_alarm   = optional(bool, false)
  }))
  default = {}
}

# ── ECS CPU Utilization ───────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  for_each = { for k, v in var.ecs_alarms : k => v if v.create_cpu_alarm }

  alarm_name          = "${local.prefix}-ecs-${each.key}-cpu-high"
  alarm_description   = "ECS service ${each.value.cluster_name}/${each.value.service_name}: CPU above ${each.value.cpu_threshold}%. Service may need more tasks or a larger task definition."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = each.value.period
  statistic           = "Average"
  threshold           = each.value.cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = each.value.cluster_name
    ServiceName = each.value.service_name
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Component = "ecs" })
}

# ── ECS Memory Utilization ────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  for_each = { for k, v in var.ecs_alarms : k => v if v.create_memory_alarm }

  alarm_name          = "${local.prefix}-ecs-${each.key}-memory-high"
  alarm_description   = "ECS service ${each.value.cluster_name}/${each.value.service_name}: memory above ${each.value.mem_threshold}%. Risk of OOM kills and task restarts."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = each.value.period
  statistic           = "Average"
  threshold           = each.value.mem_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = each.value.cluster_name
    ServiceName = each.value.service_name
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "ecs" })
}

# ── ECS Running Task Count Below Minimum ─────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "ecs_tasks" {
  for_each = { for k, v in var.ecs_alarms : k => v if v.create_task_alarm && v.min_task_count != null }

  alarm_name          = "${local.prefix}-ecs-${each.key}-task-count-low"
  alarm_description   = "ECS service ${each.value.cluster_name}/${each.value.service_name}: running tasks below ${each.value.min_task_count}. Tasks may be crash-looping or failing to start."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Minimum"
  threshold           = each.value.min_task_count
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = each.value.cluster_name
    ServiceName = each.value.service_name
  }

  alarm_actions = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "ecs" })
}
