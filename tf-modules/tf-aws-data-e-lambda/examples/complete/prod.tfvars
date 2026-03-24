# =============================================================================
# Prod — VPC Lambda + all production features
# =============================================================================
aws_region    = "us-east-1"
environment   = "prod"
function_name = "my-api-handler"
name_prefix   = "prod"
project       = "myapp"
owner         = "platform-team"
cost_center   = "CC-1234"
description   = "API handler - production"

tags = {
  Compliance = "PCI"
  DataClass  = "Confidential"
}

# ── IAM Role ──────────────────────────────────────────────────────────────────
# Option A: auto-create (module creates dedicated role)
create_role = true
role_arn    = null

# Option B: BYO — reuse a shared/cross-module role
# create_role = false
# role_arn    = "arn:aws:iam::123456789012:role/shared-lambda-exec-prod"

# Option C: Add extra policies to the auto-created role
managed_policy_arns = [
  "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
]

# ── Package (S3) ──────────────────────────────────────────────────────────────
package_type           = "Zip"
s3_bucket              = "my-lambda-artifacts-prod"
s3_key                 = "api-handler/v2.1.0.zip"
runtime                = "python3.12"
handler                = "app.handler"
architectures          = ["arm64"] # Graviton: cheaper + faster
memory_size            = 1024
timeout                = 60
ephemeral_storage_size = 1024

# ── VPC Lambda ────────────────────────────────────────────────────────────────
subnet_ids         = ["subnet-aaaaaaaa", "subnet-bbbbbbbb", "subnet-cccccccc"]
security_group_ids = ["sg-xxxxxxxxx"]

# ── Environment Variables ─────────────────────────────────────────────────────
environment_variables = {
  LOG_LEVEL = "INFO"
  ENV       = "prod"
  DB_HOST   = "prod-db.example.internal"
}

# ── Aliases (live + canary for safe deploys) ──────────────────────────────────
aliases = {
  live = {
    description = "Production traffic — stable version"
  }
  canary = {
    description    = "Canary — 10% of traffic on new version"
    routing_weight = 0.1
  }
}

# ── Provisioned Concurrency + Auto-Scaling ────────────────────────────────────
reserved_concurrent_executions    = 200
provisioned_concurrent_executions = 10
provisioned_concurrency_alias     = "live"

enable_autoscaling             = true
autoscaling_min_capacity       = 5
autoscaling_max_capacity       = 100
autoscaling_target_utilization = 70
autoscaling_scale_in_cooldown  = 300
autoscaling_scale_out_cooldown = 60

# ── Tracing & Logging ─────────────────────────────────────────────────────────
tracing_mode          = "Active"
log_retention_days    = 90
log_format            = "JSON"
application_log_level = "INFO"
system_log_level      = "WARN"

# ── Function URL (prod: IAM-auth only) ────────────────────────────────────────
create_function_url    = false
function_url_auth_type = "AWS_IAM"

# ── Dead Letter & Async Destinations ─────────────────────────────────────────
dead_letter_target_arn           = "arn:aws:sqs:us-east-1:123456789012:lambda-dlq-prod"
async_on_failure_destination_arn = "arn:aws:sqs:us-east-1:123456789012:lambda-failures-prod"
async_maximum_retry_attempts     = 2

# ── EventBridge Scheduler ────────────────────────────────────────────────────
schedules = {
  nightly_cleanup = {
    schedule_expression = "cron(0 2 * * ? *)"
    description         = "Nightly data cleanup job"
    input               = "{\"action\":\"cleanup\",\"dry_run\":false}"
    state               = "ENABLED"
  }
  hourly_sync = {
    schedule_expression = "rate(1 hour)"
    description         = "Hourly data sync"
    input               = "{\"action\":\"sync\"}"
    state               = "ENABLED"
  }
}

# ── SQS Event Source Mapping ──────────────────────────────────────────────────
event_source_mappings = {
  orders_queue = {
    event_source_arn                   = "arn:aws:sqs:us-east-1:123456789012:orders-queue-prod"
    batch_size                         = 10
    maximum_batching_window_in_seconds = 5
    enabled                            = true
    function_response_types            = ["ReportBatchItemFailures"]
  }
}

# ── API Gateway Trigger ───────────────────────────────────────────────────────
allowed_triggers = {
  apigw = {
    principal  = "apigateway.amazonaws.com"
    source_arn = "arn:aws:execute-api:us-east-1:123456789012:abc123def/*/*/*"
    qualifier  = "live"
  }
}

# ── CloudWatch Alarms ─────────────────────────────────────────────────────────
create_cloudwatch_alarms    = true
alarm_sns_topic_arn         = "arn:aws:sns:us-east-1:123456789012:prod-critical-alerts"
alarm_error_threshold       = 1
alarm_throttle_threshold    = 10
alarm_duration_threshold_ms = 5000
alarm_evaluation_periods    = 2
alarm_period_seconds        = 60

# ── CloudWatch Dashboard ──────────────────────────────────────────────────────
create_cloudwatch_dashboard = true

# ── Lambda Insights ───────────────────────────────────────────────────────────
enable_lambda_insights  = true
lambda_insights_version = 21
