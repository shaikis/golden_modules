# =============================================================================
# tf-aws-cloudwatch — Application Load Balancer (ALB) Alarms
#
# Creates per-ALB alarms:
#   - 5xx errors         → unhealthy targets or backend failures
#   - 4xx errors         → client errors or access control issues
#   - Target response time p99 → SLA latency breach
#   - Unhealthy host count → targets failing health checks
#
# Note: The load_balancer value must be the ALB suffix from the ARN:
#   arn:aws:elasticloadbalancing:...:loadbalancer/app/<name>/<id>
#   Use just: "app/<name>/<id>"
#
# To disable: set alb_alarms = {}
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "alb_alarms" {
  description = <<-EOT
    Map of Application Load Balancer alarm configurations.
    Key = logical name.

    The load_balancer value is the load balancer dimension (suffix from ARN):
      "app/prod-myapp-alb/0123456789abcdef"
    The target_group value (optional) is the target group dimension (suffix from ARN):
      "targetgroup/prod-myapp-tg/abcdef0123456789"

    Example:
      prod_alb = {
        load_balancer            = "app/prod-myapp-alb/0123456789abcdef"
        target_group             = "targetgroup/prod-myapp-tg/abcdef0123456789"
        error_5xx_threshold      = 10
        response_time_p99_ms     = 3000
        unhealthy_host_threshold = 1
      }
  EOT
  type = map(object({
    load_balancer            = string
    target_group             = optional(string, null)
    error_5xx_threshold      = optional(number, 10)
    error_4xx_threshold      = optional(number, 100)
    response_time_p99_ms     = optional(number, 5000)
    unhealthy_host_threshold = optional(number, 1)
    evaluation_periods       = optional(number, 2)
    period                   = optional(number, 60)
    treat_missing_data       = optional(string, "notBreaching")
    create_5xx_alarm         = optional(bool, true)
    create_4xx_alarm         = optional(bool, false)
    create_latency_alarm     = optional(bool, true)
    create_unhealthy_alarm   = optional(bool, true)
  }))
  default = {}
}

# ── ALB 5xx Errors ────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  for_each = { for k, v in var.alb_alarms : k => v if v.create_5xx_alarm }

  alarm_name          = "${local.prefix}-alb-${each.key}-5xx"
  alarm_description   = "ALB ${each.value.load_balancer}: HTTPCode_ELB_5XX_Count exceeds ${each.value.error_5xx_threshold}. Targets may be unhealthy or backend is returning errors."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = each.value.period
  statistic           = "Sum"
  threshold           = each.value.error_5xx_threshold
  treat_missing_data  = each.value.treat_missing_data

  dimensions = {
    LoadBalancer = each.value.load_balancer
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "alb" })
}

# ── ALB 4xx Errors ────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "alb_4xx" {
  for_each = { for k, v in var.alb_alarms : k => v if v.create_4xx_alarm }

  alarm_name          = "${local.prefix}-alb-${each.key}-4xx"
  alarm_description   = "ALB ${each.value.load_balancer}: 4xx error count above ${each.value.error_4xx_threshold}. Check WAF rules, auth config, or client integration issues."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "HTTPCode_ELB_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = each.value.period
  statistic           = "Sum"
  threshold           = each.value.error_4xx_threshold
  treat_missing_data  = each.value.treat_missing_data

  dimensions = {
    LoadBalancer = each.value.load_balancer
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Component = "alb" })
}

# ── ALB Target Response Time p99 ──────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  for_each = { for k, v in var.alb_alarms : k => v if v.create_latency_alarm }

  alarm_name          = "${local.prefix}-alb-${each.key}-response-time-p99"
  alarm_description   = "ALB ${each.value.load_balancer}: p99 target response time exceeds ${each.value.response_time_p99_ms}ms (${each.value.response_time_p99_ms / 1000}s). Users are experiencing slow responses."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = each.value.period
  extended_statistic  = "p99"
  threshold           = each.value.response_time_p99_ms / 1000 # ALB uses seconds
  treat_missing_data  = each.value.treat_missing_data

  dimensions = {
    LoadBalancer = each.value.load_balancer
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Component = "alb" })
}

# ── Unhealthy Host Count ──────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy" {
  for_each = { for k, v in var.alb_alarms : k => v if v.create_unhealthy_alarm && v.target_group != null }

  alarm_name          = "${local.prefix}-alb-${each.key}-unhealthy-hosts"
  alarm_description   = "ALB ${each.value.load_balancer}: ${each.value.unhealthy_host_threshold} or more targets are failing health checks. Traffic is being routed to reduced capacity."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = each.value.period
  statistic           = "Maximum"
  threshold           = each.value.unhealthy_host_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = each.value.load_balancer
    TargetGroup  = each.value.target_group
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "alb" })
}
