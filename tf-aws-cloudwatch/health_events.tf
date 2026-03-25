# =============================================================================
# tf-aws-cloudwatch — AWS Health Events
#
# Routes AWS Health events (Service Health Dashboard + Personal Health Dashboard)
# to SNS so SREs are notified BEFORE infrastructure is impacted.
#
# Event types:
#   issue              → active service degradation or outage (act now)
#   scheduledChange    → upcoming planned maintenance (prepare window)
#   accountNotification → billing or account-level notices
#
# Why this matters in practice:
#   - AWS may schedule a maintenance reboot of your RDS instance → gives you
#     a window to failover before it happens
#   - AWS announces an EC2 host retirement → you must stop/start the instance
#   - A regional service degrades → explains why your alarms are firing
#
# Important: AWS Health API is global (us-east-1 only).
# If your module is deployed in another region, health events still appear
# in EventBridge in us-east-1. You may need a cross-region event bus if you
# want to receive them in other regions.
#
# To enable: set enable_health_events = true
# To disable: set enable_health_events = false
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "enable_health_events" {
  description = <<-EOT
    Create EventBridge rules to forward AWS Health events to SNS.
    Captures service degradations, planned maintenance, and account notifications.
    Note: AWS Health events use the global endpoint (us-east-1).
  EOT
  type        = bool
  default     = false
}

variable "health_event_services" {
  description = <<-EOT
    Filter health events to specific AWS service names (UPPERCASE, as used by AWS).
    Empty list = capture health events for ALL services.
    Example: ["EC2", "RDS", "ECS", "LAMBDA", "S3", "VPC", "EKS"]
  EOT
  type        = list(string)
  default     = []
}

variable "health_event_categories" {
  description = <<-EOT
    Health event categories to capture.
    "issue"               = active service disruptions and outages (act now)
    "scheduledChange"     = planned maintenance requiring action (prepare window)
    "accountNotification" = billing or account-level notices
  EOT
  type        = list(string)
  default     = ["issue", "scheduledChange"]
}

# ── AWS Health Event Rule ─────────────────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "health_events" {
  count = var.enable_health_events ? 1 : 0

  name        = "${local.prefix}-aws-health-events"
  description = "Forward AWS Health events to SNS for SRE notification."

  event_pattern = jsonencode(merge(
    {
      source      = ["aws.health"]
      detail-type = ["AWS Health Event"]
    },
    length(var.health_event_categories) > 0 ? {
      detail = merge(
        { eventTypeCategory = var.health_event_categories },
        length(var.health_event_services) > 0 ? { service = var.health_event_services } : {}
      )
      } : (
      length(var.health_event_services) > 0 ? {
        detail = { service = var.health_event_services }
      } : {}
    )
  ))

  tags = merge(local.common_tags, { Feature = "health-events" })
}

resource "aws_cloudwatch_event_target" "health_events" {
  count = var.enable_health_events && local.effective_sns_arn != null ? 1 : 0

  rule = aws_cloudwatch_event_rule.health_events[0].name
  arn  = local.effective_sns_arn

  input_transformer {
    input_paths = {
      account     = "$.account"
      region      = "$.region"
      time        = "$.time"
      service     = "$.detail.service"
      category    = "$.detail.eventTypeCategory"
      code        = "$.detail.eventTypeCode"
      status      = "$.detail.statusCode"
      description = "$.detail.eventDescription[0].latestDescription"
      start_time  = "$.detail.startTime"
      end_time    = "$.detail.endTime"
      affected    = "$.detail.affectedEntities"
    }

    input_template = <<-TMPL
      "AWS HEALTH EVENT

      Service   : <service>
      Category  : <category>
      Status    : <status>
      Event     : <code>
      Account   : <account>
      Region    : <region>
      Time      : <time>
      Start     : <start_time>
      End       : <end_time>

      Description:
      <description>

      Affected resources:
      <affected>

      Check AWS Console -> Health Dashboard for full details and action items."
    TMPL
  }
}
