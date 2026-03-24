# =============================================================================
# tf-aws-cloudwatch — CloudTrail: Resource Deletion Alerts
#
# Creates EventBridge rules that match CloudTrail events for resource deletions.
# When a deletion event is detected:
#   1. CloudTrail records the API call and WHO made it (userIdentity)
#   2. EventBridge matches the event in near real-time (<1 minute)
#   3. SNS notification is sent with full actor details
#
# The notification includes:
#   - Which resource was deleted
#   - WHO deleted it (IAM user, assumed role, or federated identity)
#   - From which IP address
#   - Request parameters (resource ID, ARN, etc.)
#
# Prerequisite: CloudTrail must be enabled (multi-region trail recommended).
# To enable: set enable_resource_deletion_alerts = true
# To disable: set enable_resource_deletion_alerts = false
#
# Supported services:
#   ec2       → TerminateInstances
#   rds       → DeleteDBInstance, DeleteDBCluster
#   s3        → DeleteBucket
#   lambda    → DeleteFunction20150331
#   eks       → DeleteCluster
#   dynamodb  → DeleteTable
#   ecs       → DeleteCluster, DeleteService
#   vpc       → DeleteVpc
#   all       → all of the above
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "enable_resource_deletion_alerts" {
  description = <<-EOT
    Create EventBridge rules that fire when AWS resources are deleted.
    Captures who performed the action from CloudTrail userIdentity.
    Requires CloudTrail to be enabled with management events (Read + Write).
    Set deletion_alert_services to choose which services to monitor.
  EOT
  type        = bool
  default     = false
}

variable "deletion_alert_services" {
  description = <<-EOT
    Which AWS services to monitor for resource deletion.
    Valid values: "ec2", "rds", "s3", "lambda", "eks", "dynamodb", "ecs", "vpc", "all".
    Default covers the most common production resources.
  EOT
  type        = list(string)
  default     = ["ec2", "rds", "s3", "lambda", "eks", "dynamodb"]
}

variable "resource_change_sns_topic_arn" {
  description = <<-EOT
    Optional dedicated SNS topic ARN for resource change (deletion/stop) alerts.
    When null, falls back to the module's main SNS topic.
    Best practice: use a high-priority topic with P1 OpsGenie/PagerDuty routing.
  EOT
  type        = string
  default     = null
}

# ── Locals ────────────────────────────────────────────────────────────────────

locals {
  change_alert_sns_arn = var.resource_change_sns_topic_arn != null ? var.resource_change_sns_topic_arn : local.effective_sns_arn

  # Each service maps to the CloudTrail event source + event names that mean deletion
  deletion_event_map = {
    ec2      = { source = "aws.ec2", events = ["TerminateInstances"] }
    rds      = { source = "aws.rds", events = ["DeleteDBInstance", "DeleteDBCluster"] }
    s3       = { source = "aws.s3", events = ["DeleteBucket"] }
    lambda   = { source = "aws.lambda", events = ["DeleteFunction20150331"] }
    eks      = { source = "aws.eks", events = ["DeleteCluster"] }
    dynamodb = { source = "aws.dynamodb", events = ["DeleteTable"] }
    ecs      = { source = "aws.ecs", events = ["DeleteCluster", "DeleteService"] }
    vpc      = { source = "aws.ec2", events = ["DeleteVpc"] }
  }

  # If "all" is in the list, monitor every service; otherwise filter to requested ones
  active_deletion_services = contains(var.deletion_alert_services, "all") ? keys(local.deletion_event_map) : [
    for s in var.deletion_alert_services : s if contains(keys(local.deletion_event_map), s)
  ]

  # Build the EventBridge target map (only when alerts enabled and SNS is configured)
  deletion_target_map = var.enable_resource_deletion_alerts && local.change_alert_sns_arn != null ? {
    for s in local.active_deletion_services : s => local.deletion_event_map[s]
  } : {}
}

# ── EventBridge Rules ─────────────────────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "resource_deleted" {
  for_each = var.enable_resource_deletion_alerts ? {
    for s in local.active_deletion_services : s => local.deletion_event_map[s]
  } : {}

  name        = "${local.prefix}-${each.key}-deleted"
  description = "Alert when ${each.key} resources are deleted. Source: CloudTrail."

  # EventBridge matches CloudTrail management events in near real-time
  event_pattern = jsonencode({
    source      = [each.value.source]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = each.value.events
    }
  })

  tags = merge(local.common_tags, { Feature = "cloudtrail-deletion" })
}

# ── EventBridge Targets → SNS ─────────────────────────────────────────────────

resource "aws_cloudwatch_event_target" "resource_deleted" {
  for_each = local.deletion_target_map

  rule = aws_cloudwatch_event_rule.resource_deleted[each.key].name
  arn  = local.change_alert_sns_arn

  # Transform the CloudTrail event into a human-readable notification
  # that includes the full actor identity and request parameters.
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
      user_agent = "$.detail.userAgent"
      request    = "$.detail.requestParameters"
    }

    input_template = <<-TMPL
      "RESOURCE DELETED: <event>

      Account   : <account>
      Region    : <region>
      Time      : <time>
      Action    : <event>

      Who did it:
        Identity  : <user_type>
        User ARN  : <user_arn>
        Username  : <user_name>
        Role      : <assumed_by>
        Source IP : <source_ip>
        User-Agent: <user_agent>

      Request details:
        <request>

      If this deletion was unintended, check CloudTrail immediately.
      AWS Console -> CloudTrail -> Event history -> Filter by event name: <event>"
    TMPL
  }
}
