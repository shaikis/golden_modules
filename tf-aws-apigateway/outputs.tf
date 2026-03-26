output "api_id" {
  description = "ID of the HTTP API."
  value       = aws_apigatewayv2_api.this.id
}

output "api_arn" {
  description = "ARN of the HTTP API."
  value       = aws_apigatewayv2_api.this.arn
}

output "api_endpoint" {
  description = "Base endpoint URL of the API (without stage)."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "invoke_url" {
  description = "Full invocation URL including stage. Use as Slack Request URL base."
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "stage_id" {
  description = "ID of the deployment stage."
  value       = aws_apigatewayv2_stage.this.id
}

output "execution_arn" {
  description = "Execution ARN of the API (used in Lambda resource policies)."
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "access_log_group_name" {
  description = "CloudWatch Log Group name for API access logs."
  value       = var.enable_access_logs ? aws_cloudwatch_log_group.access_logs[0].name : ""
}

output "access_log_group_arn" {
  description = "CloudWatch Log Group ARN for API access logs."
  value       = var.enable_access_logs ? aws_cloudwatch_log_group.access_logs[0].arn : ""
}
