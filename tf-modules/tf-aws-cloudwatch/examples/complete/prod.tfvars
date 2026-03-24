# =============================================================================
# Production environment — full feature configuration
# =============================================================================
# How to deploy:
#   terraform init
#   export TF_VAR_opsgenie_endpoint_url="https://api.opsgenie.com/v1/json/amazonsns?apiKey=YOUR_KEY"
#   export TF_VAR_pagerduty_endpoint_url="https://events.pagerduty.com/integration/YOUR_KEY/enqueue"
#   terraform apply -var-file=prod.tfvars

# ── Naming ────────────────────────────────────────────────────────────────────
name        = "myapp"
name_prefix = "prod"
environment = "prod"
project     = "myproject"
owner       = "platform-team"
cost_center = "CC-001"

tags = {
  Tier        = "production"
  Criticality = "high"
  DR          = "required"
}

# ── SNS Topic (KMS-encrypted in prod) ────────────────────────────────────────
create_sns_topic = true
sns_topic_arn    = null
sns_kms_key_id   = "arn:aws:kms:us-east-1:123456789012:key/mrk-00000000000000000000000000000000"

# ── Notifications ─────────────────────────────────────────────────────────────
# OpsGenie: set via TF_VAR_opsgenie_endpoint_url environment variable
# PagerDuty: set via TF_VAR_pagerduty_endpoint_url environment variable
email_endpoints = [
  "prod-alerts@example.com",
  "oncall@example.com"
]
opsgenie_endpoint_url  = null # override with TF_VAR_opsgenie_endpoint_url
pagerduty_endpoint_url = null # override with TF_VAR_pagerduty_endpoint_url

# SQS queue for ServiceNow / Jira downstream ticket creation
alarm_sqs_queue_arn = "arn:aws:sqs:us-east-1:123456789012:prod-alarm-routing-queue"

# ── Monitored Resources ───────────────────────────────────────────────────────
lambda_function_name   = "prod-myapp-processor"
rds_instance_id        = "prod-myapp-postgres"
rds_has_replica        = true
sqs_queue_name         = "prod-myapp-orders-queue"
sqs_dlq_name           = "prod-myapp-orders-dlq"
dynamodb_table_name    = "prod-myapp-sessions"
asg_name               = "prod-myapp-asg"
alb_name               = "prod-myapp-alb"
alb_target_group       = "prod-myapp-tg"
ecs_cluster_name       = "prod-myapp-cluster"
ecs_service_name       = "prod-myapp-api"
elasticache_cluster_id = "prod-myapp-redis"
api_endpoint           = "api.myapp.com"

# ACM certificates to monitor for expiry
acm_certificate_arns = [
  "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
]

# ── Feature Toggles ───────────────────────────────────────────────────────────
enable_backup_alarms = true
create_dashboard     = true
dashboard_name       = "prod-myapp-operations"

# EventBridge → SQS for ServiceNow integration
enable_eventbridge_routing = true
eventbridge_target_arn     = "arn:aws:sqs:us-east-1:123456789012:prod-alarm-routing-queue"

# ── CloudTrail / Security ─────────────────────────────────────────────────────
# Deletion alerts: who deleted EC2/RDS/S3/Lambda/EKS etc.
enable_deletion_alerts = true

# Stop alerts: who stopped EC2/RDS
enable_stop_alerts = true

# Use a DEDICATED high-priority SNS topic for deletion/stop alerts
# This routes to a P1 OpsGenie team with immediate escalation
change_alert_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:prod-p1-critical-alerts"

# Security alerts: root usage, IAM changes, SG changes, S3 policy changes
enable_security_alerts = true
security_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:prod-security-alerts"

# GuardDuty: crypto-mining, data exfil, compromised creds (HIGH/CRITICAL only)
enable_guardduty_alerts = true

# AWS Health: service degradations + maintenance windows
enable_health_events = true

# Cost anomaly: alert when costs spike unexpectedly > $200
enable_cost_anomaly    = true
cost_anomaly_threshold = 200
