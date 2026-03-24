# =============================================================================
# tf-aws-cloudwatch — Core Variables
# (Naming, Tags, SNS Topic, Notification Integrations)
#
# Feature-specific variables live in their respective feature files:
#   alarms_generic.tf       — metric_alarms, anomaly_detection_alarms, composite_alarms
#   alarms_log_filters.tf   — log_metric_filters
#   alarms_asg.tf           — asg_alarms
#   alarms_backup.tf        — backup_alarms
#   alarms_rds.tf           — rds_alarms
#   alarms_api_gateway.tf   — api_gateway_alarms
#   alarms_ecs.tf           — ecs_alarms
#   alarms_alb.tf           — alb_alarms
#   alarms_elasticache.tf   — elasticache_alarms
#   alarms_acm.tf           — acm_certificate_arns + expiry thresholds
#   synthetics.tf           — synthetics_canaries, canary_execution_role_arn
#   cloudtrail_deletion.tf  — enable_resource_deletion_alerts + related
#   cloudtrail_stop.tf      — enable_resource_stop_alerts + related
#   security_alerts.tf      — enable_security_alerts, enable_guardduty_alerts
#   health_events.tf        — enable_health_events + related
#   cost_anomaly.tf         — enable_cost_anomaly_detection + related
#   eventbridge_routing.tf  — enable_eventbridge_routing + related
#   dashboard.tf            — create_dashboard, dashboard_name, dashboard_services
# =============================================================================

# ── Naming & Tagging ──────────────────────────────────────────────────────────

variable "name" {
  description = "Base name used to prefix all CloudWatch resources."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix: <prefix>-<name>. Example: 'prod' → 'prod-myapp'."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod). Added to all resource tags."
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name for tagging and custom metric namespaces."
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owning team for tagging (e.g., 'platform-team')."
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center code for tagging and billing attribution."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags merged onto all resources created by this module."
  type        = map(string)
  default     = {}
}

# ── SNS Topic (BYO or create) ─────────────────────────────────────────────────
# Option A (default): create_sns_topic = true  + sns_topic_arn = null → module creates topic
# Option B:           create_sns_topic = false + sns_topic_arn = "arn" → reuse existing topic

variable "create_sns_topic" {
  description = <<-EOT
    Create a new SNS topic for alarm notifications.
    Set false and provide sns_topic_arn to reuse an existing topic (BYO pattern).
  EOT
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "Existing SNS topic ARN. When provided, module skips topic creation."
  type        = string
  default     = null
}

variable "sns_kms_key_id" {
  description = "KMS key ID or ARN for SNS topic at-rest encryption. Recommended for production."
  type        = string
  default     = null
}

# ── Alarm Notification Integrations ──────────────────────────────────────────
# All integrations subscribe to the module's SNS topic.
# Multiple integrations can be active simultaneously.

variable "email_endpoints" {
  description = <<-EOT
    List of email addresses to subscribe to the SNS topic.
    AWS sends a confirmation email to each address — users must click the link.
    Best for: dev/staging alerts, team distribution lists.
  EOT
  type        = list(string)
  default     = []
}

variable "opsgenie_endpoint_url" {
  description = <<-EOT
    OpsGenie SNS integration HTTPS endpoint URL.
    How to get it: OpsGenie → Teams → <team> → Integrations → Add Amazon SNS → copy the URL.
    Format: https://api.opsgenie.com/v1/json/amazonsns?apiKey=<key>
    Pass via TF_VAR_opsgenie_endpoint_url env var to keep out of state files.
  EOT
  type        = string
  default     = null
  sensitive   = true
}

variable "pagerduty_endpoint_url" {
  description = <<-EOT
    PagerDuty SNS integration HTTPS endpoint URL.
    How to get it: PagerDuty → Services → <service> → Integrations → Add Amazon CloudWatch.
    Format: https://events.pagerduty.com/integration/<key>/enqueue
    Pass via TF_VAR_pagerduty_endpoint_url env var to keep out of state files.
  EOT
  type        = string
  default     = null
  sensitive   = true
}

variable "slack_webhook_url" {
  description = <<-EOT
    Slack incoming webhook URL for direct Slack notifications (no AWS Chatbot required).
    Creates an SNS → Lambda → Slack forwarding pipeline.
    Pass via TF_VAR_slack_webhook_url env var.
  EOT
  type        = string
  default     = null
  sensitive   = true
}

variable "alarm_sqs_queue_arn" {
  description = <<-EOT
    SQS queue ARN to receive raw alarm payloads.
    Use for custom downstream routing: Jira, ServiceNow, custom Lambda processors, etc.
  EOT
  type        = string
  default     = null
}
