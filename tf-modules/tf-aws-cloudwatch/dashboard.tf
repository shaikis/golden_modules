# =============================================================================
# tf-aws-cloudwatch — CloudWatch Dashboard
#
# Creates a single multi-service operations dashboard.
# Auto-generates widget rows for each service type specified in dashboard_services.
#
# Supported widget sections (enabled by adding resources to the respective list):
#   lambda_functions → Invocations, Errors, Throttles per function
#   rds_instances    → CPU, Connections, FreeStorageSpace per DB
#   sqs_queues       → Queue depth, Message age, Sent count per queue
#   asg_names        → CPU, InService instances, Desired capacity per ASG
#   alb_names        → RequestCount, p99 latency, 5xx errors per ALB
#   ecs_clusters     → ECS cluster CPU + memory (requires Container Insights)
#   ec2_instance_ids → Per-instance CPU utilization
#
# To enable: set create_dashboard = true
# To disable: set create_dashboard = false
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "create_dashboard" {
  description = "Create a CloudWatch dashboard aggregating all configured service metrics."
  type        = bool
  default     = false
}

variable "dashboard_name" {
  description = "Dashboard name override. Defaults to <prefix>-overview."
  type        = string
  default     = null
}

variable "dashboard_services" {
  description = <<-EOT
    Service resource lists for auto-generating dashboard widget groups.
    Each list entry adds a metrics widget row for that service.
  EOT
  type = object({
    lambda_functions = optional(list(string), [])
    rds_instances    = optional(list(string), [])
    ecs_clusters     = optional(list(string), [])
    ecs_services     = optional(map(string), {}) # { service_name = cluster_name }
    sqs_queues       = optional(list(string), [])
    alb_names        = optional(list(string), [])
    ec2_instance_ids = optional(list(string), [])
    asg_names        = optional(list(string), [])
  })
  default = {}
}

# ── Dashboard Locals ──────────────────────────────────────────────────────────

locals {
  _region = data.aws_region.current.name

  # Title banner
  _title_widget = [{
    type   = "text"
    x      = 0
    y      = 0
    width  = 24
    height = 2
    properties = {
      markdown = "# ${local.prefix} — Operations Dashboard\n**Environment:** `${var.environment}` | **Region:** `${local._region}` | **Project:** `${var.project}`"
    }
  }]

  # Lambda: Invocations / Errors / Throttles
  _lambda_widgets = [
    for idx, fn in var.dashboard_services.lambda_functions : {
      type   = "metric"
      x      = 0
      y      = 3 + (idx * 7)
      width  = 8
      height = 6
      properties = {
        title  = "Lambda: ${fn}"
        view   = "timeSeries"
        region = local._region
        period = 60
        metrics = [
          ["AWS/Lambda", "Invocations", "FunctionName", fn, { stat = "Sum", label = "Invocations" }],
          ["AWS/Lambda", "Errors", "FunctionName", fn, { stat = "Sum", color = "#d62728", label = "Errors" }],
          ["AWS/Lambda", "Throttles", "FunctionName", fn, { stat = "Sum", color = "#ff7f0e", label = "Throttles" }]
        ]
      }
    }
  ]

  # RDS: CPU / Connections / FreeStorage
  _rds_widgets = [
    for idx, db in var.dashboard_services.rds_instances : {
      type   = "metric"
      x      = 8
      y      = 3 + (idx * 7)
      width  = 8
      height = 6
      properties = {
        title  = "RDS: ${db}"
        view   = "timeSeries"
        region = local._region
        period = 60
        metrics = [
          ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", db, { stat = "Average", label = "CPU %" }],
          ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", db, { stat = "Average", yAxis = "right", label = "Connections" }],
          ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", db, { stat = "Average", yAxis = "right", label = "Free Storage" }]
        ]
      }
    }
  ]

  # SQS: Queue depth / Oldest message age / Sent count
  _sqs_widgets = [
    for idx, q in var.dashboard_services.sqs_queues : {
      type   = "metric"
      x      = 16
      y      = 3 + (idx * 7)
      width  = 8
      height = 6
      properties = {
        title  = "SQS: ${q}"
        view   = "timeSeries"
        region = local._region
        period = 60
        metrics = [
          ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", q, { stat = "Maximum", label = "Queue Depth" }],
          ["AWS/SQS", "ApproximateAgeOfOldestMessage", "QueueName", q, { stat = "Maximum", color = "#d62728", yAxis = "right", label = "Oldest Msg (s)" }],
          ["AWS/SQS", "NumberOfMessagesSent", "QueueName", q, { stat = "Sum", label = "Sent" }]
        ]
      }
    }
  ]

  # ASG: CPU / InService count / Desired capacity
  _asg_widgets = [
    for idx, asg in var.dashboard_services.asg_names : {
      type   = "metric"
      x      = 0
      y      = 100 + (idx * 7)
      width  = 12
      height = 6
      properties = {
        title  = "ASG: ${asg}"
        view   = "timeSeries"
        region = local._region
        period = 60
        metrics = [
          ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", asg, { stat = "Average", label = "CPU %" }],
          ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", asg, { stat = "Average", yAxis = "right", label = "InService" }],
          ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", asg, { stat = "Average", yAxis = "right", label = "Desired" }]
        ]
      }
    }
  ]

  # ALB: RequestCount / p99 latency / 5xx errors
  _alb_widgets = [
    for idx, alb in var.dashboard_services.alb_names : {
      type   = "metric"
      x      = 12
      y      = 100 + (idx * 7)
      width  = 12
      height = 6
      properties = {
        title  = "ALB: ${alb}"
        view   = "timeSeries"
        region = local._region
        period = 60
        metrics = [
          ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", alb, { stat = "Sum", label = "Requests" }],
          ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", alb, { stat = "p99", yAxis = "right", label = "p99 latency (s)" }],
          ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", alb, { stat = "Sum", color = "#d62728", label = "5xx Errors" }]
        ]
      }
    }
  ]

  # ECS Cluster: CPUReservation / MemoryReservation
  _ecs_widgets = [
    for idx, cluster in var.dashboard_services.ecs_clusters : {
      type   = "metric"
      x      = 0
      y      = 200 + (idx * 7)
      width  = 12
      height = 6
      properties = {
        title  = "ECS Cluster: ${cluster}"
        view   = "timeSeries"
        region = local._region
        period = 60
        metrics = [
          ["AWS/ECS", "CPUReservation", "ClusterName", cluster, { stat = "Average", label = "CPU Reservation %" }],
          ["AWS/ECS", "MemoryReservation", "ClusterName", cluster, { stat = "Average", label = "Memory Reservation %" }]
        ]
      }
    }
  ]

  # Combine all widget groups
  _all_widgets = concat(
    local._title_widget,
    local._lambda_widgets,
    local._rds_widgets,
    local._sqs_widgets,
    local._asg_widgets,
    local._alb_widgets,
    local._ecs_widgets
  )
}

# ── Dashboard Resource ────────────────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "this" {
  count = var.create_dashboard ? 1 : 0

  dashboard_name = coalesce(var.dashboard_name, "${local.prefix}-overview")
  dashboard_body = jsonencode({ widgets = local._all_widgets })
}
