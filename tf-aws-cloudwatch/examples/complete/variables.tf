# ── Naming & Tagging ──────────────────────────────────────────────────────────

variable "name" {
  description = "Base name used to prefix all CloudWatch resources."
  type        = string
  default     = "myapp"
}

variable "name_prefix" {
  description = "Optional prefix prepended as <prefix>-<name>."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name for tagging and metric namespaces."
  type        = string
  default     = "myproject"
}

variable "owner" {
  description = "Owning team for tagging."
  type        = string
  default     = "platform-team"
}

variable "cost_center" {
  description = "Cost center code for tagging and billing attribution."
  type        = string
  default     = "CC-001"
}

variable "tags" {
  description = "Additional tags merged onto all resources."
  type        = map(string)
  default     = {}
}

# ── SNS Topic ─────────────────────────────────────────────────────────────────

variable "create_sns_topic" {
  description = "Create a new SNS topic. Set false and provide sns_topic_arn to reuse existing."
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "Existing SNS topic ARN to use instead of creating a new one (BYO)."
  type        = string
  default     = null
}

variable "sns_kms_key_id" {
  description = "KMS key ID or ARN for SNS topic at-rest encryption."
  type        = string
  default     = null
}

# ── Notification Integrations ─────────────────────────────────────────────────

variable "email_endpoints" {
  description = "List of email addresses to subscribe to alarm notifications."
  type        = list(string)
  default     = []
}

variable "opsgenie_endpoint_url" {
  description = "OpsGenie SNS HTTPS integration endpoint URL. Use TF_VAR_opsgenie_endpoint_url."
  type        = string
  default     = null
  sensitive   = true
}

variable "pagerduty_endpoint_url" {
  description = "PagerDuty SNS HTTPS integration endpoint URL. Use TF_VAR_pagerduty_endpoint_url."
  type        = string
  default     = null
  sensitive   = true
}

variable "alarm_sqs_queue_arn" {
  description = "SQS queue ARN to receive raw alarm notifications for ITSM routing (ServiceNow, Jira)."
  type        = string
  default     = null
}

# ── Monitored Resources ───────────────────────────────────────────────────────

variable "lambda_function_name" {
  description = "Name of the Lambda function to monitor."
  type        = string
  default     = "my-lambda-function"
}

variable "rds_instance_id" {
  description = "RDS DB instance identifier to monitor."
  type        = string
  default     = "my-rds-instance"
}

variable "rds_has_replica" {
  description = "Set true if the RDS instance has a read replica (enables replica lag alarm)."
  type        = bool
  default     = false
}

variable "sqs_queue_name" {
  description = "SQS main queue name to monitor."
  type        = string
  default     = "my-sqs-queue"
}

variable "sqs_dlq_name" {
  description = "SQS dead-letter queue name to monitor."
  type        = string
  default     = "my-sqs-dlq"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name to monitor for throttles and errors."
  type        = string
  default     = "my-dynamodb-table"
}

variable "asg_name" {
  description = "Auto Scaling Group name to monitor."
  type        = string
  default     = "my-asg"
}

variable "alb_name" {
  description = "Application Load Balancer name (not ARN) to monitor."
  type        = string
  default     = "my-alb"
}

variable "alb_target_group" {
  description = "ALB target group name to monitor for unhealthy host count."
  type        = string
  default     = "my-target-group"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name to monitor."
  type        = string
  default     = "my-ecs-cluster"
}

variable "ecs_service_name" {
  description = "ECS service name within the cluster to monitor."
  type        = string
  default     = "my-ecs-service"
}

variable "elasticache_cluster_id" {
  description = "ElastiCache cluster ID to monitor."
  type        = string
  default     = "my-redis-cluster"
}

variable "acm_certificate_arns" {
  description = "List of ACM certificate ARNs to monitor for upcoming expiry (warning 30d, critical 7d)."
  type        = list(string)
  default     = []
}

variable "api_endpoint" {
  description = "API hostname for Synthetics canary health checks (e.g. api.example.com)."
  type        = string
  default     = "api.example.com"
}

# ── Feature Toggles ───────────────────────────────────────────────────────────

variable "enable_backup_alarms" {
  description = "Enable AWS Backup failure alarms (backup, restore, and copy jobs)."
  type        = bool
  default     = false
}

variable "create_dashboard" {
  description = "Create a CloudWatch dashboard aggregating all service metrics."
  type        = bool
  default     = false
}

variable "dashboard_name" {
  description = "CloudWatch dashboard name override. Defaults to <prefix>-overview."
  type        = string
  default     = null
}

variable "enable_eventbridge_routing" {
  description = "Create EventBridge rule to forward alarm state changes to a target (SQS/Lambda)."
  type        = bool
  default     = false
}

variable "eventbridge_target_arn" {
  description = "ARN of the EventBridge target (SQS queue, Lambda, or Event Bus) for ITSM routing."
  type        = string
  default     = null
}

# ── CloudTrail / Security Toggles ─────────────────────────────────────────────

variable "enable_deletion_alerts" {
  description = "Alert when production resources (EC2, RDS, S3, Lambda, etc.) are deleted."
  type        = bool
  default     = false
}

variable "enable_stop_alerts" {
  description = "Alert when EC2 instances or RDS databases are stopped."
  type        = bool
  default     = false
}

variable "change_alert_sns_topic_arn" {
  description = "Dedicated high-priority SNS topic for deletion/stop alerts. Null = use main topic."
  type        = string
  default     = null
}

variable "enable_security_alerts" {
  description = "Alert on root usage, IAM changes, security group changes, S3 policy changes."
  type        = bool
  default     = false
}

variable "security_sns_topic_arn" {
  description = "Dedicated SNS topic for security alerts (recommended: separate from ops alarms)."
  type        = string
  default     = null
}

variable "enable_guardduty_alerts" {
  description = "Forward GuardDuty HIGH/CRITICAL findings to SNS (requires GuardDuty enabled)."
  type        = bool
  default     = false
}

variable "enable_health_events" {
  description = "Forward AWS Health service degradations and maintenance windows to SNS."
  type        = bool
  default     = false
}

variable "enable_cost_anomaly" {
  description = "Enable AWS Cost Anomaly Detection (ML-based cost spike alerts)."
  type        = bool
  default     = false
}

variable "cost_anomaly_threshold" {
  description = "Alert when anomalous cost impact exceeds this dollar amount."
  type        = number
  default     = 100
}
