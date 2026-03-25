output "table_arns" {
  description = "ARNs of all standard DynamoDB tables."
  value       = module.dynamodb.table_arns
}

output "table_names" {
  description = "Names of all standard DynamoDB tables."
  value       = module.dynamodb.table_names
}

output "table_stream_arns" {
  description = "Stream ARNs for tables with streams enabled."
  value       = module.dynamodb.table_stream_arns
}

output "global_table_arns" {
  description = "ARNs of global DynamoDB tables."
  value       = module.dynamodb.global_table_arns
}

output "backup_plan_arn" {
  description = "ARN of the AWS Backup plan."
  value       = module.dynamodb.backup_plan_arn
}

output "backup_vault_arn" {
  description = "ARN of the AWS Backup vault."
  value       = module.dynamodb.backup_vault_arn
}

output "read_only_role_arn" {
  description = "ARN of the read-only IAM role."
  value       = module.dynamodb.read_only_role_arn
}

output "read_write_role_arn" {
  description = "ARN of the read-write IAM role."
  value       = module.dynamodb.read_write_role_arn
}

output "stream_consumer_role_arn" {
  description = "ARN of the stream consumer IAM role."
  value       = module.dynamodb.stream_consumer_role_arn
}

output "alarm_arns" {
  description = "All CloudWatch alarm ARNs."
  value       = module.dynamodb.alarm_arns
}

output "autoscaling_policy_arns" {
  description = "Auto-scaling policy ARNs."
  value       = module.dynamodb.autoscaling_policy_arns
}
