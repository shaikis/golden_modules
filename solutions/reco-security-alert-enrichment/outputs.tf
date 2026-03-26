# ── S3 Buckets ─────────────────────────────────────────────────────────────────
output "input_bucket_name" {
  description = "Name of the S3 input bucket (upload raw alert JSON files here)."
  value       = module.s3_input.bucket_id
}

output "input_bucket_arn" {
  description = "ARN of the S3 input bucket."
  value       = module.s3_input.bucket_arn
}

output "output_bucket_name" {
  description = "Name of the S3 output bucket (enriched alert JSON results)."
  value       = module.s3_output.bucket_id
}

output "output_bucket_arn" {
  description = "ARN of the S3 output bucket."
  value       = module.s3_output.bucket_arn
}

output "examples_bucket_name" {
  description = "Name of the S3 examples bucket (upload few-shot examples JSON to few-shot/examples.json)."
  value       = module.s3_examples.bucket_id
}

output "examples_bucket_arn" {
  description = "ARN of the S3 examples bucket."
  value       = module.s3_examples.bucket_arn
}

# ── Lambda ─────────────────────────────────────────────────────────────────────
output "lambda_function_name" {
  description = "Name of the alert enrichment Lambda function."
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the alert enrichment Lambda function."
  value       = module.lambda.function_arn
}

output "lambda_log_group_name" {
  description = "CloudWatch Log Group name for the Lambda function."
  value       = module.lambda.log_group_name
}

output "lambda_cloudwatch_dashboard_url" {
  description = "URL to the Lambda CloudWatch dashboard."
  value       = module.lambda.cloudwatch_dashboard_url
}

# ── SQS ────────────────────────────────────────────────────────────────────────
output "sqs_queue_url" {
  description = "URL of the alert processing SQS queue."
  value       = module.sqs.queue_url
}

output "sqs_queue_arn" {
  description = "ARN of the alert processing SQS queue."
  value       = module.sqs.queue_arn
}

output "sqs_dlq_url" {
  description = "URL of the Dead Letter Queue."
  value       = module.sqs.dlq_url
}

output "sqs_dlq_arn" {
  description = "ARN of the Dead Letter Queue."
  value       = module.sqs.dlq_arn
}

# ── IAM ────────────────────────────────────────────────────────────────────────
output "lambda_role_arn" {
  description = "ARN of the Lambda execution IAM role."
  value       = module.lambda_role.role_arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution IAM role."
  value       = module.lambda_role.role_name
}

# ── KMS ────────────────────────────────────────────────────────────────────────
output "kms_key_arn" {
  description = "ARN of the KMS encryption key. Null when enable_kms_encryption = false."
  value       = local.kms_key_arn
}

# ── SNS ────────────────────────────────────────────────────────────────────────
output "sns_alert_topic_arn" {
  description = "ARN of the SNS alert topic. Null when alarm_email is not set."
  value       = var.alarm_email != null ? module.sns_alerts[0].topic_arn : null
}

# ── Bedrock ────────────────────────────────────────────────────────────────────
output "bedrock_guardrail_id" {
  description = "Bedrock guardrail ID enforced on every Claude invocation. Empty when enable_bedrock_guardrail = false."
  value       = local.bedrock_guardrail_id
}

output "bedrock_guardrail_arn" {
  description = "Bedrock guardrail ARN. Empty when enable_bedrock_guardrail = false."
  value       = var.enable_bedrock_guardrail ? module.bedrock.guardrail_arns["security-alerts"] : ""
}

output "bedrock_invocation_log_prefix" {
  description = "S3 URI prefix where Bedrock model invocation logs are written. Empty when logging is disabled."
  value       = var.enable_bedrock_logging ? "s3://${module.s3_output.bucket_id}/bedrock-invocation-logs/" : ""
}
