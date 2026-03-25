# =============================================================================
# Dev — Simple Lambda (no VPC, auto-create role, JSON logs, Function URL)
# =============================================================================
aws_region    = "us-east-1"
environment   = "dev"
function_name = "my-api-handler"
name_prefix   = "dev"
project       = "myapp"
owner         = "platform-team"
description   = "API handler - dev"

# ── IAM Role ──────────────────────────────────────────────────────────────────
# Auto-create role (default)
create_role = true
role_arn    = null
# BYO: uncomment to pass from root module
# create_role = false
# role_arn    = "arn:aws:iam::123456789012:role/shared-lambda-role"

# ── Package (S3) ──────────────────────────────────────────────────────────────
package_type = "Zip"
s3_bucket    = "my-lambda-artifacts-dev"
s3_key       = "api-handler/latest.zip"
runtime      = "python3.12"
handler      = "app.handler"
memory_size  = 256
timeout      = 30

# ── Simple Lambda (no VPC) ────────────────────────────────────────────────────
subnet_ids         = []
security_group_ids = []

environment_variables = {
  LOG_LEVEL = "DEBUG"
  ENV       = "dev"
  DB_HOST   = "dev-db.example.internal"
}

# ── Function URL (dev: public for easy testing) ───────────────────────────────
create_function_url    = true
function_url_auth_type = "NONE"
function_url_cors = {
  allow_origins = ["*"]
  allow_methods = ["GET", "POST"]
  allow_headers = ["Content-Type", "Authorization"]
}

# ── Aliases ───────────────────────────────────────────────────────────────────
aliases = {}

# ── Concurrency ───────────────────────────────────────────────────────────────
reserved_concurrent_executions    = -1
provisioned_concurrent_executions = 0
enable_autoscaling                = false

# ── Tracing & Logging ─────────────────────────────────────────────────────────
tracing_mode          = "PassThrough"
log_retention_days    = 7
log_format            = "JSON"
application_log_level = "DEBUG"

# ── Alarms & Dashboard ────────────────────────────────────────────────────────
create_cloudwatch_alarms    = false
create_cloudwatch_dashboard = false
enable_lambda_insights      = false

# ── Schedules ────────────────────────────────────────────────────────────────
schedules             = {}
event_source_mappings = {}
