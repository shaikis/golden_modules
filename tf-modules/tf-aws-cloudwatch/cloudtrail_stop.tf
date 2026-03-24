# =============================================================================
# tf-aws-cloudwatch — CloudTrail: Resource Stop / Shutdown Alerts
#
# Fires when someone STOPS (not terminates) EC2 instances or RDS databases.
# Common real-world scenarios:
#   - A developer accidentally stops a prod RDS instance via console
#   - A script or scheduled task stops instances unexpectedly
#   - An insider or compromised credential stops workloads maliciously
#   - After-hours maintenance causes unplanned downtime
#
# Unlike termination events, stop events are recoverable — but still cause
# downtime. This alert tells the SRE team WHO stopped it and WHEN, enabling
# immediate investigation and restart if needed.
#
# Prerequisite: CloudTrail with management events enabled.
# To enable: set enable_resource_stop_alerts = true
# To disable: set enable_resource_stop_alerts = false
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "enable_resource_stop_alerts" {
  description = <<-EOT
    Create EventBridge rules that fire when EC2 instances or RDS databases are stopped.
    Captures the full actor identity from CloudTrail userIdentity.
    Covers: EC2 StopInstances, RDS StopDBInstance, StopDBCluster.
  EOT
  type        = bool
  default     = false
}

# ── Locals ────────────────────────────────────────────────────────────────────

locals {
  stop_event_map = {
    ec2 = { source = "aws.ec2", events = ["StopInstances"] }
    rds = { source = "aws.rds", events = ["StopDBInstance", "StopDBCluster"] }
  }

  stop_target_map = var.enable_resource_stop_alerts && local.change_alert_sns_arn != null ? local.stop_event_map : {}
}

# ── EventBridge Rules ─────────────────────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "resource_stopped" {
  for_each = var.enable_resource_stop_alerts ? local.stop_event_map : {}

  name        = "${local.prefix}-${each.key}-stopped"
  description = "Alert when ${each.key} resources are stopped. Source: CloudTrail."

  event_pattern = jsonencode({
    source      = [each.value.source]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = each.value.events
    }
  })

  tags = merge(local.common_tags, { Feature = "cloudtrail-stop" })
}

# ── EventBridge Targets → SNS ─────────────────────────────────────────────────

resource "aws_cloudwatch_event_target" "resource_stopped" {
  for_each = local.stop_target_map

  rule = aws_cloudwatch_event_rule.resource_stopped[each.key].name
  arn  = local.change_alert_sns_arn

  input_transformer {
    input_paths = {
      account    = "$.account"
      region     = "$.region"
      time       = "$.time"
      event      = "$.detail.eventName"
      user_type  = "$.detail.userIdentity.type"
      user_arn   = "$.detail.userIdentity.arn"
      user_name  = "$.detail.userIdentity.userName"
      assumed_by = "$.detail.userIdentity.sessionContext.sessionIssuer.userName"
      source_ip  = "$.detail.sourceIPAddress"
      request    = "$.detail.requestParameters"
    }

    input_template = <<-TMPL
      "RESOURCE STOPPED: <event>

      Account   : <account>
      Region    : <region>
      Time      : <time>
      Action    : <event>

      Who stopped it:
        Identity  : <user_type>
        User ARN  : <user_arn>
        Username  : <user_name>
        Role      : <assumed_by>
        Source IP : <source_ip>

      Request details:
        <request>

      This may be causing service downtime. Verify this was intentional.
      If unexpected, restart the resource immediately and investigate.
      AWS Console -> EC2/RDS console to restart the stopped resource."
    TMPL
  }
}
