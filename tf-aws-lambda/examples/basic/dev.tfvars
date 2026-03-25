aws_region    = "us-east-1"
environment   = "dev"
function_name = "my-lambda"
name_prefix   = "dev"
project       = "myapp"
owner         = "platform-team"
description   = "My Lambda function - dev"

# ── IAM Role ──────────────────────────────────────────────────────────────────
# Option A (default): let module create a new role automatically
create_role = true
role_arn    = null

# Option B: uncomment to pass an existing role from the root module
# create_role = false
# role_arn    = "arn:aws:iam::123456789012:role/my-existing-lambda-role"

# ── Runtime ───────────────────────────────────────────────────────────────────
runtime     = "python3.12"
handler     = "index.handler"
memory_size = 128
timeout     = 30
filename    = "lambda.zip"

# prod — S3 (CI uploads, Terraform just references)
s3_bucket = "my-lambda-artifacts-prod"
s3_key    = "api-handler/v2.1.0.zip"

environment_variables = {
  LOG_LEVEL = "DEBUG"
  ENV       = "dev"
}

# ── CloudWatch ────────────────────────────────────────────────────────────────
log_retention_days       = 7
create_cloudwatch_alarms = false
