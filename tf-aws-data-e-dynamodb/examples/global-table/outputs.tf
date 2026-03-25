output "global_table_arns" {
  description = "ARNs of the global DynamoDB tables."
  value       = module.dynamodb_global.global_table_arns
}

output "global_table_names" {
  description = "Names of the global DynamoDB tables."
  value       = module.dynamodb_global.global_table_names
}

output "global_table_stream_arns" {
  description = "Stream ARNs for global tables."
  value       = module.dynamodb_global.global_table_stream_arns
}

output "read_only_role_arn" {
  description = "ARN of the read-only IAM role."
  value       = module.dynamodb_global.read_only_role_arn
}

output "read_write_role_arn" {
  description = "ARN of the read-write IAM role."
  value       = module.dynamodb_global.read_write_role_arn
}

output "alarm_arns" {
  description = "Replication latency alarm ARNs."
  value       = module.dynamodb_global.alarm_arns
}
