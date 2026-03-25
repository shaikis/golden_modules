# =============================================================================
# tf-aws-cloudwatch — Log Metric Filters
#
# Extracts a custom metric from CloudWatch Log data using a filter pattern,
# then optionally creates an alarm on the extracted metric.
#
# Real-world use cases:
#   - Count ERROR log lines in application logs
#   - Count specific business events (payment_failed, login_failed)
#   - Extract numeric values (response_time, order_value) from structured logs
#   - Alert on security events (AccessDenied, UnauthorizedAccess)
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "log_metric_filters" {
  description = <<-EOT
    Map of CloudWatch Log metric filters.
    Each entry extracts a custom metric from a log group and optionally creates an alarm.
    Key = logical filter name.

    Examples:
      app_errors = {
        log_group_name   = "/aws/lambda/my-function"
        filter_pattern   = "[timestamp, requestId, level=ERROR, message]"
        metric_name      = "AppErrors"
        create_alarm     = true
        alarm_threshold  = 1
      }
      payment_failures = {
        log_group_name   = "/app/payments"
        filter_pattern   = "{ $.event = \"payment_failed\" }"
        metric_name      = "PaymentFailures"
        metric_value     = "$.amount"   # extract numeric value from log field
        create_alarm     = true
        alarm_threshold  = 5
      }
      security_denied = {
        log_group_name   = "/aws/cloudtrail/logs"
        filter_pattern   = "{ $.errorCode = \"AccessDenied\" }"
        metric_name      = "AccessDeniedCount"
        create_alarm     = true
        alarm_threshold  = 10
      }
  EOT
  type = map(object({
    log_group_name      = string
    filter_pattern      = string
    metric_name         = string
    metric_namespace    = optional(string, "CustomMetrics")
    metric_value        = optional(string, "1")
    default_value       = optional(number, null)
    unit                = optional(string, "Count")
    create_alarm        = optional(bool, false)
    alarm_threshold     = optional(number, 1)
    alarm_period        = optional(number, 60)
    evaluation_periods  = optional(number, 1)
    alarm_description   = optional(string, "")
    treat_missing_data  = optional(string, "notBreaching")
    comparison_operator = optional(string, "GreaterThanOrEqualToThreshold")
    severity            = optional(string, "warning")
  }))
  default = {}
}

# ── Log Metric Filters ────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_metric_filter" "this" {
  for_each = var.log_metric_filters

  name           = "${local.prefix}-${each.key}"
  pattern        = each.value.filter_pattern
  log_group_name = each.value.log_group_name

  metric_transformation {
    name          = each.value.metric_name
    namespace     = each.value.metric_namespace
    value         = each.value.metric_value
    default_value = each.value.default_value
    unit          = each.value.unit
  }
}

# ── Alarms on Log Metric Filters ─────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "log_filter" {
  for_each = { for k, v in var.log_metric_filters : k => v if v.create_alarm }

  alarm_name          = "${local.prefix}-${each.key}-log-alarm"
  alarm_description   = each.value.alarm_description != "" ? each.value.alarm_description : "Log metric filter alarm: ${each.value.metric_name} in ${each.value.log_group_name}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.metric_namespace
  period              = each.value.alarm_period
  statistic           = "Sum"
  threshold           = each.value.alarm_threshold
  treat_missing_data  = each.value.treat_missing_data

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = each.value.severity, Type = "log-metric-filter" })

  depends_on = [aws_cloudwatch_log_metric_filter.this]
}
