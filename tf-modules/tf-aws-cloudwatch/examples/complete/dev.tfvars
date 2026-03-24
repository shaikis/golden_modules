# =============================================================================
# Development environment — minimal configuration
# Email notifications only. No security/CloudTrail/health/cost features.
# =============================================================================

# ── Naming ────────────────────────────────────────────────────────────────────
name        = "myapp"
name_prefix = "dev"
environment = "dev"
project     = "myproject"
owner       = "platform-team"
cost_center = "CC-001"

tags = {
  Tier = "non-production"
}

# ── SNS Topic ─────────────────────────────────────────────────────────────────
create_sns_topic = true
sns_topic_arn    = null
sns_kms_key_id   = null

# ── Notifications ─────────────────────────────────────────────────────────────
email_endpoints        = ["dev-alerts@example.com"]
opsgenie_endpoint_url  = null
pagerduty_endpoint_url = null
alarm_sqs_queue_arn    = null

# ── Monitored Resources ───────────────────────────────────────────────────────
lambda_function_name   = "dev-myapp-processor"
rds_instance_id        = "dev-myapp-postgres"
rds_has_replica        = false
sqs_queue_name         = "dev-myapp-orders-queue"
sqs_dlq_name           = "dev-myapp-orders-dlq"
dynamodb_table_name    = "dev-myapp-sessions"
asg_name               = "dev-myapp-asg"
alb_name               = "dev-myapp-alb"
alb_target_group       = "dev-myapp-tg"
ecs_cluster_name       = "dev-myapp-cluster"
ecs_service_name       = "dev-myapp-api"
elasticache_cluster_id = "dev-myapp-redis"
api_endpoint           = "api-dev.myapp.com"
acm_certificate_arns   = []

# ── Feature Toggles ───────────────────────────────────────────────────────────
enable_backup_alarms       = false
create_dashboard           = false
dashboard_name             = null
enable_eventbridge_routing = false
eventbridge_target_arn     = null

# ── CloudTrail / Security (disabled in dev) ───────────────────────────────────
enable_deletion_alerts     = false
enable_stop_alerts         = false
change_alert_sns_topic_arn = null
enable_security_alerts     = false
security_sns_topic_arn     = null
enable_guardduty_alerts    = false
enable_health_events       = false
enable_cost_anomaly        = false
cost_anomaly_threshold     = 100
