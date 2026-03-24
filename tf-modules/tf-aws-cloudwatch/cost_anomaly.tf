# =============================================================================
# tf-aws-cloudwatch — AWS Cost Anomaly Detection
#
# Uses AWS Cost Explorer's ML-based anomaly detection to identify unexpected
# cost spikes. Unlike CloudWatch budget alerts (which only check fixed thresholds),
# anomaly detection learns your normal spend pattern and fires when deviations occur.
#
# Common real-world causes of cost anomalies:
#   - Lambda function in infinite retry loop (invocations skyrocket)
#   - NAT Gateway data transfer spike (someone transferred large dataset)
#   - EC2 instance type accidentally changed to large family
#   - S3 Glacier restore for large dataset
#   - Forgotten long-running EC2 spot fleet
#   - DDoS attack causing data transfer costs
#   - Wrong region deployment (running in expensive region accidentally)
#
# Prerequisite: AWS Cost Explorer must be enabled (free to enable, hourly data
# has additional cost). Enable at: AWS Console -> Cost Management -> Cost Explorer.
#
# To enable: set enable_cost_anomaly_detection = true
# To disable: set enable_cost_anomaly_detection = false
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "enable_cost_anomaly_detection" {
  description = <<-EOT
    Create an AWS Cost Anomaly Detection monitor and SNS subscription.
    Requires AWS Cost Explorer to be enabled in the account.
    Alerts when unexpected cost increases exceed the configured dollar threshold.
  EOT
  type        = bool
  default     = false
}

variable "cost_anomaly_threshold_dollars" {
  description = "Alert when anomalous cost impact exceeds this dollar amount. Set higher for large accounts."
  type        = number
  default     = 100
}

variable "cost_anomaly_monitor_type" {
  description = <<-EOT
    Cost anomaly monitor type:
      "DIMENSIONAL" = monitors the entire AWS account (total spend, by service)
      "CUSTOM"      = monitors specific services (combine with cost_anomaly_services)
  EOT
  type        = string
  default     = "DIMENSIONAL"
}

variable "cost_anomaly_services" {
  description = <<-EOT
    List of AWS services to monitor for cost anomalies (used when monitor_type = CUSTOM).
    Leave empty when using DIMENSIONAL monitor type.
    Example: ["Amazon EC2", "AWS Lambda", "Amazon RDS", "Amazon S3"]
  EOT
  type        = list(string)
  default     = []
}

# ── Cost Anomaly Monitor ──────────────────────────────────────────────────────
# The monitor defines WHAT to watch (whole account vs specific service dimension)

resource "aws_ce_anomaly_monitor" "this" {
  count = var.enable_cost_anomaly_detection ? 1 : 0

  name         = "${local.prefix}-cost-monitor"
  monitor_type = var.cost_anomaly_monitor_type

  # For DIMENSIONAL monitors, specify the dimension (SERVICE = per-service monitoring)
  monitor_dimension = var.cost_anomaly_monitor_type == "DIMENSIONAL" ? "SERVICE" : null

  # For CUSTOM monitors, specify a cost expression filter
  dynamic "monitor_specification" {
    for_each = var.cost_anomaly_monitor_type == "CUSTOM" && length(var.cost_anomaly_services) > 0 ? [1] : []
    content {
      # Filter to specific services
      filter = jsonencode({
        Dimensions = {
          Key    = "SERVICE"
          Values = var.cost_anomaly_services
        }
      })
    }
  }

  tags = local.common_tags
}

# ── Cost Anomaly Subscription ─────────────────────────────────────────────────
# The subscription defines HOW to alert (threshold + SNS destination)

resource "aws_ce_anomaly_subscription" "this" {
  count = var.enable_cost_anomaly_detection && local.effective_sns_arn != null ? 1 : 0

  name      = "${local.prefix}-cost-subscription"
  frequency = "DAILY" # IMMEDIATE = alert per anomaly, DAILY = digest, WEEKLY = summary

  monitor_arn_list = [aws_ce_anomaly_monitor.this[0].arn]

  subscriber {
    address = local.effective_sns_arn
    type    = "SNS"
  }

  # Alert when the anomalous spend exceeds the dollar threshold
  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = [tostring(var.cost_anomaly_threshold_dollars)]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }

  tags = local.common_tags
}

# ── SNS Topic Policy for Cost Anomaly ────────────────────────────────────────
# The cost anomaly detection service needs permission to publish to the SNS topic.
# This is only needed when the module creates the SNS topic (not BYO).

resource "aws_sns_topic_policy" "cost_anomaly" {
  count = var.enable_cost_anomaly_detection && var.create_sns_topic && var.sns_topic_arn == null ? 1 : 0

  arn = aws_sns_topic.this[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCostAnomalyDetection"
        Effect = "Allow"
        Principal = {
          Service = "costalerts.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.this[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}
