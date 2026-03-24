variable "aws_region" {
  description = "AWS region for deployment."
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS account ID."
  type        = string
  default     = "123456789012"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "prod"
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic for CloudWatch alarm notifications."
  type        = string
  default     = "arn:aws:sns:us-east-1:123456789012:ops-alerts"
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL for notifications."
  type        = string
  sensitive   = true
  default     = "https://hooks.slack.com/services/placeholder"
}

variable "pagerduty_endpoint" {
  description = "PagerDuty EventBridge API endpoint."
  type        = string
  sensitive   = true
  default     = "https://events.pagerduty.com/v2/enqueue"
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Team        = "platform"
  }
}
