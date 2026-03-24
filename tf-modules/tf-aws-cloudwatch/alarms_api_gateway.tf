# =============================================================================
# tf-aws-cloudwatch — API Gateway Alarms (REST API)
#
# Creates per-API alarms (toggle each alarm type per entry):
#   - 5xx errors         → server-side errors; your API/backend is failing
#   - 4xx errors         → client errors; possible bad inputs or auth failures
#   - Latency p99        → p99 latency breaching SLA threshold
#   - Integration latency → backend response time (excludes API GW overhead)
#
# To disable: set api_gateway_alarms = {}
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "api_gateway_alarms" {
  description = <<-EOT
    Map of API Gateway REST API alarm configurations.
    Key = logical name. api_name and stage_name identify the target API.

    Example:
      payments_api = {
        api_name             = "prod-payments-api"
        stage_name           = "prod"
        error_5xx_threshold  = 5
        error_4xx_threshold  = 100
        latency_p99_ms       = 3000
        create_5xx_alarm     = true
        create_latency_alarm = true
      }
  EOT
  type = map(object({
    api_name                         = string
    stage_name                       = string
    error_5xx_threshold              = optional(number, 5)
    error_4xx_threshold              = optional(number, 100)
    latency_p99_ms                   = optional(number, 5000)
    integration_latency_p99_ms       = optional(number, 4000)
    evaluation_periods               = optional(number, 2)
    period                           = optional(number, 60)
    treat_missing_data               = optional(string, "notBreaching")
    create_5xx_alarm                 = optional(bool, true)
    create_4xx_alarm                 = optional(bool, false)
    create_latency_alarm             = optional(bool, true)
    create_integration_latency_alarm = optional(bool, false)
  }))
  default = {}
}

# ── 5xx Error Alarm ───────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  for_each = { for k, v in var.api_gateway_alarms : k => v if v.create_5xx_alarm }

  alarm_name          = "${local.prefix}-apigw-${each.key}-5xx"
  alarm_description   = "API Gateway ${each.value.api_name}/${each.value.stage_name}: 5xx error rate is above ${each.value.error_5xx_threshold} per minute. Backend service failures detected."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = each.value.period
  statistic           = "Sum"
  threshold           = each.value.error_5xx_threshold
  treat_missing_data  = each.value.treat_missing_data

  dimensions = {
    ApiName = each.value.api_name
    Stage   = each.value.stage_name
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "api-gateway" })
}

# ── 4xx Error Alarm ───────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "apigw_4xx" {
  for_each = { for k, v in var.api_gateway_alarms : k => v if v.create_4xx_alarm }

  alarm_name          = "${local.prefix}-apigw-${each.key}-4xx"
  alarm_description   = "API Gateway ${each.value.api_name}/${each.value.stage_name}: 4xx error rate above ${each.value.error_4xx_threshold}. Possible auth failures, throttling, or bad client requests."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = each.value.period
  statistic           = "Sum"
  threshold           = each.value.error_4xx_threshold
  treat_missing_data  = each.value.treat_missing_data

  dimensions = {
    ApiName = each.value.api_name
    Stage   = each.value.stage_name
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Component = "api-gateway" })
}

# ── Latency p99 ───────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "apigw_latency" {
  for_each = { for k, v in var.api_gateway_alarms : k => v if v.create_latency_alarm }

  alarm_name          = "${local.prefix}-apigw-${each.key}-latency-p99"
  alarm_description   = "API Gateway ${each.value.api_name}/${each.value.stage_name}: p99 latency exceeds ${each.value.latency_p99_ms}ms. End-user experience is degraded."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = each.value.period
  extended_statistic  = "p99"
  threshold           = each.value.latency_p99_ms
  treat_missing_data  = each.value.treat_missing_data

  dimensions = {
    ApiName = each.value.api_name
    Stage   = each.value.stage_name
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Component = "api-gateway" })
}

# ── Integration Latency p99 ───────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "apigw_integration_latency" {
  for_each = { for k, v in var.api_gateway_alarms : k => v if v.create_integration_latency_alarm }

  alarm_name          = "${local.prefix}-apigw-${each.key}-integration-latency-p99"
  alarm_description   = "API Gateway ${each.value.api_name}/${each.value.stage_name}: p99 backend integration latency exceeds ${each.value.integration_latency_p99_ms}ms. Backend service is slow."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "IntegrationLatency"
  namespace           = "AWS/ApiGateway"
  period              = each.value.period
  extended_statistic  = "p99"
  threshold           = each.value.integration_latency_p99_ms
  treat_missing_data  = each.value.treat_missing_data

  dimensions = {
    ApiName = each.value.api_name
    Stage   = each.value.stage_name
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Component = "api-gateway" })
}
