# =============================================================================
# tf-aws-cloudwatch — SNS Topic + Subscriptions
#
# BYO Pattern:
#   create_sns_topic = true  + sns_topic_arn = null  → module creates new topic
#   create_sns_topic = false + sns_topic_arn = "arn" → use existing topic
#
# Subscriptions (all optional, any combination):
#   email_endpoints        — email confirmation required
#   opsgenie_endpoint_url  — OpsGenie alert creation
#   pagerduty_endpoint_url — PagerDuty incident creation
#   alarm_sqs_queue_arn    — SQS for custom downstream routing
# =============================================================================

resource "aws_sns_topic" "this" {
  count = var.create_sns_topic && var.sns_topic_arn == null ? 1 : 0

  name              = "${local.prefix}-alarms"
  kms_master_key_id = var.sns_kms_key_id
  tags              = local.common_tags
}

# Allow CloudWatch alarms and EventBridge rules to publish
resource "aws_sns_topic_policy" "this" {
  count = var.create_sns_topic && var.sns_topic_arn == null ? 1 : 0

  arn = aws_sns_topic.this[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountOwner"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "SNS:*"
        Resource = aws_sns_topic.this[0].arn
      },
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.this[0].arn
      },
      {
        Sid    = "AllowEventBridge"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.this[0].arn
      }
    ]
  })
}

# ── Email Subscriptions ───────────────────────────────────────────────────────
# AWS sends confirmation emails — recipients must click the link to activate.

resource "aws_sns_topic_subscription" "email" {
  for_each = local.effective_sns_arn != null ? toset(var.email_endpoints) : toset([])

  topic_arn = local.effective_sns_arn
  protocol  = "email"
  endpoint  = each.value
}

# ── OpsGenie Integration ──────────────────────────────────────────────────────
# CloudWatch alarm JSON → SNS → OpsGenie → alert with auto-close on OK
# OpsGenie parses the AlarmName, NewStateReason, and dimensions automatically.

resource "aws_sns_topic_subscription" "opsgenie" {
  count = local.effective_sns_arn != null && var.opsgenie_endpoint_url != null ? 1 : 0

  topic_arn              = local.effective_sns_arn
  protocol               = "https"
  endpoint               = var.opsgenie_endpoint_url
  endpoint_auto_confirms = true
  raw_message_delivery   = false # OpsGenie needs the full SNS envelope
}

# ── PagerDuty Integration ─────────────────────────────────────────────────────
# CloudWatch alarm JSON → SNS → PagerDuty → incident with auto-resolve on OK

resource "aws_sns_topic_subscription" "pagerduty" {
  count = local.effective_sns_arn != null && var.pagerduty_endpoint_url != null ? 1 : 0

  topic_arn              = local.effective_sns_arn
  protocol               = "https"
  endpoint               = var.pagerduty_endpoint_url
  endpoint_auto_confirms = true
  raw_message_delivery   = false
}

# ── SQS Subscription ─────────────────────────────────────────────────────────
# Feeds alarms to SQS for downstream processing (ServiceNow, Jira, custom Lambda)

resource "aws_sns_topic_subscription" "sqs" {
  count = local.effective_sns_arn != null && var.alarm_sqs_queue_arn != null ? 1 : 0

  topic_arn            = local.effective_sns_arn
  protocol             = "sqs"
  endpoint             = var.alarm_sqs_queue_arn
  raw_message_delivery = true # raw JSON for easier SQS consumer parsing
}
