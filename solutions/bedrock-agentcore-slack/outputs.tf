output "slack_webhook_url" {
  description = "PASTE THIS URL into Slack App > Event Subscriptions > Request URL."
  value       = "${module.api_gateway.invoke_url}/slack/events"
}

output "api_gateway_invoke_url" {
  description = "Base invocation URL of the HTTP API."
  value       = module.api_gateway.invoke_url
}

output "api_gateway_id" {
  description = "API Gateway ID."
  value       = module.api_gateway.api_id
}

output "lambda_verification_name" {
  description = "Slack verification Lambda function name."
  value       = module.lambda_verification.function_name
}

output "lambda_sqs_integration_name" {
  description = "SQS integration Lambda function name."
  value       = module.lambda_sqs_integration.function_name
}

output "lambda_agent_integration_name" {
  description = "Agent integration Lambda function name."
  value       = module.lambda_agent_integration.function_name
}

output "lambda_agent_dashboard_url" {
  description = "CloudWatch dashboard URL for the agent integration Lambda."
  value       = module.lambda_agent_integration.cloudwatch_dashboard_url
}

output "sqs_queue_url" {
  description = "URL of the SQS FIFO queue."
  value       = module.sqs.queue_url
}

output "sqs_dlq_url" {
  description = "URL of the Dead Letter Queue."
  value       = module.sqs.dlq_url
}

output "slack_secret_arn" {
  description = "ARN of the Secrets Manager secret holding Slack credentials."
  value       = module.secret_slack.secret_arn
}

output "ecr_repository_url" {
  description = "ECR repository URL for the agent container image."
  value       = module.ecr.repository_urls["agent"]
}

output "codebuild_project_name" {
  description = "CodeBuild project name for building the agent container image."
  value       = module.codebuild.project_name
}

output "bedrock_agent_id" {
  description = "Bedrock Agent ID."
  value       = aws_bedrock_agent_agent.slack_agent.agent_id
}

output "bedrock_agent_alias_id" {
  description = "Bedrock Agent Alias ID."
  value       = aws_bedrock_agent_agent_alias.slack_agent.agent_alias_id
}

output "bedrock_guardrail_id" {
  description = "Bedrock guardrail ID enforced on every agent invocation."
  value       = local.bedrock_guardrail_id
}

output "bedrock_invocation_log_prefix" {
  description = "S3 URI for Bedrock invocation logs."
  value       = var.enable_bedrock_logging ? "s3://${module.s3_artifacts.bucket_id}/bedrock-invocation-logs/" : ""
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution IAM role."
  value       = module.lambda_role.role_arn
}

output "kms_key_arn" {
  description = "ARN of the KMS encryption key."
  value       = local.kms_key_arn
}
