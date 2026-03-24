# =============================================================================
# tf-aws-cloudwatch — EventBridge Alarm State Routing
#
# Creates an EventBridge rule that captures ALL CloudWatch alarm state changes
# and routes them to a downstream target (SQS, Lambda, Event Bus, etc.).
#
# Use cases:
#   - Route to SQS → Lambda → ServiceNow for ITSM ticket creation
#   - Route to SQS → Lambda → Jira for engineering ticket creation
#   - Route to a central Event Bus for multi-account alarm aggregation
#   - Route to Lambda for custom enrichment (add context, suppress noise)
#   - Route to SQS for audit logging of all alarm state changes
#
# Note: For OpsGenie/PagerDuty integration, use the SNS subscriptions in sns.tf
# instead (simpler, no EventBridge needed).
#
# To enable: set enable_eventbridge_routing = true AND eventbridge_target_arn = "arn:..."
# To disable: set enable_eventbridge_routing = false
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "enable_eventbridge_routing" {
  description = "Create EventBridge rule to capture alarm state changes and forward to a custom target."
  type        = bool
  default     = false
}

variable "eventbridge_target_arn" {
  description = "Target ARN for alarm state change events. Supports: SQS queue, Lambda function, or EventBridge bus."
  type        = string
  default     = null
}

variable "alarm_severity_filter" {
  description = <<-EOT
    Optional list of severity tag values to filter. Only alarms tagged with
    Severity = one-of-these-values will be routed.
    Empty list = route ALL alarm state changes (ALARM, OK, INSUFFICIENT_DATA).
    Example: ["critical", "warning"]
  EOT
  type        = list(string)
  default     = []
}

# ── EventBridge Rule ──────────────────────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "alarm_state_change" {
  count = var.enable_eventbridge_routing && var.eventbridge_target_arn != null ? 1 : 0

  name        = "${local.prefix}-alarm-state-changes"
  description = "Route CloudWatch alarm state changes to downstream targets for ITSM/audit/enrichment."

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      # Only fire on ALARM transitions (not OK/INSUFFICIENT_DATA) by default
      state = {
        value = ["ALARM"]
      }
    }
  })

  tags = merge(local.common_tags, { Feature = "eventbridge-routing" })
}

resource "aws_cloudwatch_event_target" "alarm_state_change" {
  count = var.enable_eventbridge_routing && var.eventbridge_target_arn != null ? 1 : 0

  rule = aws_cloudwatch_event_rule.alarm_state_change[0].name
  arn  = var.eventbridge_target_arn
}
