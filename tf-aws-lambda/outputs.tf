# ── Function ──────────────────────────────────────────────────────────────────
output "function_name" {
  description = "Lambda function name."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "Lambda function ARN (unqualified)."
  value       = aws_lambda_function.this.arn
}

output "function_version" {
  description = "Latest published version number."
  value       = aws_lambda_function.this.version
}

output "qualified_arn" {
  description = "Qualified ARN including the version number."
  value       = aws_lambda_function.this.qualified_arn
}

output "invoke_arn" {
  description = "Invoke ARN used by API Gateway / AppSync to invoke this function."
  value       = aws_lambda_function.this.invoke_arn
}

# ── IAM ───────────────────────────────────────────────────────────────────────
output "role_arn" {
  description = "Effective execution role ARN (module-created or BYO)."
  value       = local.effective_role_arn
}

output "role_name" {
  description = "Execution role name. Null when a BYO role_arn was supplied."
  value       = var.create_role && var.role_arn == null ? aws_iam_role.lambda[0].name : null
}

# ── Aliases ───────────────────────────────────────────────────────────────────
output "alias_arns" {
  description = "Map of alias name → ARN."
  value       = { for k, v in aws_lambda_alias.this : k => v.arn }
}

output "alias_invoke_arns" {
  description = "Map of alias name → invoke ARN."
  value       = { for k, v in aws_lambda_alias.this : k => v.invoke_arn }
}

# ── Lambda Layers (created by module) ────────────────────────────────────────
output "created_layer_arns" {
  description = "Map of layer logical key → ARN of module-created Lambda Layers."
  value       = { for k, v in aws_lambda_layer_version.this : k => v.arn }
}

# ── Function URL ──────────────────────────────────────────────────────────────
output "function_url" {
  description = "Lambda Function URL HTTPS endpoint. Null when create_function_url = false."
  value       = var.create_function_url ? aws_lambda_function_url.this[0].function_url : null
}

output "function_url_id" {
  description = "Unique identifier of the Lambda Function URL."
  value       = var.create_function_url ? aws_lambda_function_url.this[0].url_id : null
}

# ── CloudWatch Logs ───────────────────────────────────────────────────────────
output "log_group_name" {
  description = "CloudWatch Log Group name (/aws/lambda/<function_name>)."
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "CloudWatch Log Group ARN."
  value       = aws_cloudwatch_log_group.this.arn
}

# ── CloudWatch Alarms ─────────────────────────────────────────────────────────
output "cloudwatch_alarm_errors_arn" {
  description = "ARN of the Lambda errors alarm. Null when alarms are disabled."
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.errors[0].arn : null
}

output "cloudwatch_alarm_throttles_arn" {
  description = "ARN of the Lambda throttles alarm. Null when alarms are disabled."
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.throttles[0].arn : null
}

output "cloudwatch_alarm_duration_arn" {
  description = "ARN of the Lambda duration alarm. Null when disabled."
  value       = var.create_cloudwatch_alarms && var.alarm_duration_threshold_ms > 0 ? aws_cloudwatch_metric_alarm.duration[0].arn : null
}

# ── CloudWatch Dashboard ──────────────────────────────────────────────────────
output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name. Null when create_cloudwatch_dashboard = false."
  value       = var.create_cloudwatch_dashboard ? aws_cloudwatch_dashboard.this[0].dashboard_name : null
}

output "cloudwatch_dashboard_url" {
  description = "Direct URL to the CloudWatch Lambda dashboard."
  value       = var.create_cloudwatch_dashboard ? "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${aws_cloudwatch_dashboard.this[0].dashboard_name}" : null
}

# ── EventBridge Schedules ─────────────────────────────────────────────────────
output "schedule_arns" {
  description = "Map of schedule logical key → EventBridge Scheduler schedule ARN."
  value       = { for k, v in aws_scheduler_schedule.this : k => v.arn }
}

# ── Code Signing ──────────────────────────────────────────────────────────────
output "code_signing_config_arn" {
  description = "Code Signing Config ARN. Null when code signing is not configured."
  value       = local.effective_code_signing_config_arn
}
