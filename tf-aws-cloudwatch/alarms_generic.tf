# =============================================================================
# tf-aws-cloudwatch — Generic Metric Alarms
#
# Covers: any AWS namespace or custom metric, anomaly detection (ML-based),
# and composite alarms (AND/OR logic to suppress alert storms).
#
# Feature files for service-specific alarms:
#   alarms_rds.tf, alarms_asg.tf, alarms_alb.tf, alarms_api_gateway.tf,
#   alarms_ecs.tf, alarms_elasticache.tf, alarms_backup.tf, alarms_acm.tf
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "metric_alarms" {
  description = <<-EOT
    Map of CloudWatch metric alarms. Works with ANY AWS namespace or custom metrics.
    Key = logical alarm name (used as suffix in alarm name: <prefix>-<key>).

    Examples:
      lambda_errors = {
        namespace   = "AWS/Lambda"
        metric_name = "Errors"
        dimensions  = { FunctionName = "my-fn" }
        statistic   = "Sum"
        threshold   = 1
      }
      rds_cpu = {
        namespace   = "AWS/RDS"
        metric_name = "CPUUtilization"
        dimensions  = { DBInstanceIdentifier = "my-db" }
        threshold   = 80
      }
      custom_app_metric = {
        namespace   = "MyApp/Metrics"
        metric_name = "FailedPayments"
        dimensions  = { Service = "checkout" }
        statistic   = "Sum"
        threshold   = 5
      }
  EOT
  type = map(object({
    namespace                 = string
    metric_name               = string
    dimensions                = map(string)
    threshold                 = number
    comparison_operator       = optional(string, "GreaterThanOrEqualToThreshold")
    statistic                 = optional(string, "Average")
    period                    = optional(number, 60)
    evaluation_periods        = optional(number, 1)
    datapoints_to_alarm       = optional(number, null)
    treat_missing_data        = optional(string, "notBreaching")
    alarm_description         = optional(string, "")
    unit                      = optional(string, null)
    actions_enabled           = optional(bool, true)
    alarm_actions             = optional(list(string), [])
    ok_actions                = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    severity                  = optional(string, "warning")
  }))
  default = {}
}

variable "anomaly_detection_alarms" {
  description = <<-EOT
    Map of CloudWatch anomaly detection alarms (ML-based dynamic thresholds).
    AWS learns the normal baseline automatically — no fixed threshold needed.
    Fires when the metric falls outside the expected band.
    Best for: metrics with time-of-day or day-of-week patterns (latency, traffic, CPU).
    Key = logical alarm name.
  EOT
  type = map(object({
    namespace           = string
    metric_name         = string
    dimensions          = map(string)
    statistic           = optional(string, "Average")
    period              = optional(number, 300)
    evaluation_periods  = optional(number, 2)
    band_width          = optional(number, 2) # standard deviations; higher = less sensitive
    comparison_operator = optional(string, "GreaterThanUpperThresholdMetricValue")
    alarm_description   = optional(string, "")
    treat_missing_data  = optional(string, "notBreaching")
  }))
  default = {}
}

variable "composite_alarms" {
  description = <<-EOT
    Map of composite alarms combining multiple alarms with AND/OR logic.
    Reduces alert storms — fires only when multiple conditions are true simultaneously.
    Key = logical composite alarm name.

    Example:
      high_load = {
        alarm_rule        = "ALARM(\"prod-myapp-lambda_errors\") AND ALARM(\"prod-myapp-sqs_message_age\")"
        alarm_description = "Both Lambda errors AND SQS backlog are high — possible cascading failure"
      }
    Tip: use ALARM(), OK(), INSUFFICIENT_DATA() functions in alarm_rule expressions.
  EOT
  type = map(object({
    alarm_rule        = string
    alarm_description = optional(string, "")
    actions_enabled   = optional(bool, true)
    alarm_actions     = optional(list(string), [])
    ok_actions        = optional(list(string), [])
  }))
  default = {}
}

# ── Generic Metric Alarms ─────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "metric" {
  for_each = var.metric_alarms

  alarm_name          = "${local.prefix}-${each.key}"
  alarm_description   = each.value.alarm_description != "" ? each.value.alarm_description : "${each.value.metric_name} alarm"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  treat_missing_data  = each.value.treat_missing_data
  actions_enabled     = each.value.actions_enabled
  unit                = each.value.unit
  datapoints_to_alarm = each.value.datapoints_to_alarm

  dimensions = each.value.dimensions

  alarm_actions             = length(each.value.alarm_actions) > 0 ? each.value.alarm_actions : local.default_alarm_actions
  ok_actions                = length(each.value.ok_actions) > 0 ? each.value.ok_actions : local.default_alarm_actions
  insufficient_data_actions = each.value.insufficient_data_actions

  tags = merge(local.common_tags, { Severity = each.value.severity })
}

# ── Anomaly Detection Alarms ──────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "anomaly" {
  for_each = var.anomaly_detection_alarms

  alarm_name          = "${local.prefix}-${each.key}-anomaly"
  alarm_description   = each.value.alarm_description != "" ? each.value.alarm_description : "Anomaly detected: ${each.value.metric_name}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  treat_missing_data  = each.value.treat_missing_data

  metric_query {
    id          = "m1"
    return_data = false
    metric {
      metric_name = each.value.metric_name
      namespace   = each.value.namespace
      period      = each.value.period
      stat        = each.value.statistic
      dimensions  = each.value.dimensions
    }
  }

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, ${each.value.band_width})"
    label       = "${each.value.metric_name} (expected band)"
    return_data = true
  }

  threshold_metric_id = "e1"

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Type = "anomaly-detection" })
}

# ── Composite Alarms ──────────────────────────────────────────────────────────

resource "aws_cloudwatch_composite_alarm" "this" {
  for_each = var.composite_alarms

  alarm_name        = "${local.prefix}-${each.key}-composite"
  alarm_description = each.value.alarm_description
  alarm_rule        = each.value.alarm_rule
  actions_enabled   = each.value.actions_enabled

  alarm_actions = length(each.value.alarm_actions) > 0 ? each.value.alarm_actions : local.default_alarm_actions
  ok_actions    = length(each.value.ok_actions) > 0 ? each.value.ok_actions : local.default_alarm_actions

  tags = merge(local.common_tags, { Type = "composite" })
}
