aws_region    = "us-east-1"
environment   = "prod"
function_name = "my-lambda"
name_prefix   = "prod"
project       = "myapp"
owner         = "platform-team"
description   = "My Lambda function - production"

# ── IAM Role ──────────────────────────────────────────────────────────────────
# Option A: auto-create
create_role = true
role_arn    = null
# Option B: BYO from another module / shared role
# create_role = false
# role_arn    = "arn:aws:iam::123456789012:role/shared-lambda-exec-role"

runtime     = "python3.12"
handler     = "index.handler"
memory_size = 512
timeout     = 60
filename    = "lambda.zip"

# prod — S3 (CI uploads, Terraform just references)
s3_bucket = "my-lambda-artifacts-prod"
s3_key    = "api-handler/v2.1.0.zip"

environment_variables = {
  LOG_LEVEL = "INFO"
  ENV       = "prod"
}

log_retention_days       = 90
create_cloudwatch_alarms = true
alarm_error_threshold    = 1
alarm_sns_topic_arn      = "arn:aws:sns:us-east-1:123456789012:prod-alerts"
