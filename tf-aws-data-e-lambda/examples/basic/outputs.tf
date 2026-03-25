output "function_name" {
  description = "Lambda function name."
  value       = module.lambda.function_name
}

output "function_arn" {
  description = "Lambda function ARN."
  value       = module.lambda.function_arn
}

output "invoke_arn" {
  description = "Invoke ARN for API Gateway integration."
  value       = module.lambda.invoke_arn
}

output "role_arn" {
  description = "Execution role ARN (auto-created or BYO)."
  value       = module.lambda.role_arn
}

output "log_group_name" {
  description = "CloudWatch Log Group name."
  value       = module.lambda.log_group_name
}
