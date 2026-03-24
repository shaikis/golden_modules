aws_region    = "us-east-1"
environment   = "staging"
function_name = "my-lambda"
name_prefix   = "staging"
project       = "myapp"
owner         = "platform-team"
description   = "My Lambda function - staging"

create_role = true
role_arn    = null

runtime     = "python3.12"
handler     = "index.handler"
memory_size = 256
timeout     = 30
filename    = "lambda.zip"

environment_variables = {
  LOG_LEVEL = "INFO"
  ENV       = "staging"
}

log_retention_days       = 14
create_cloudwatch_alarms = true
alarm_error_threshold    = 3
