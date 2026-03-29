output "service_a_role_arn" {
  description = "Central account role that grants KMS access by alias pattern."
  value       = module.service_a_role.role_arn
}

output "service_b_role_arn" {
  description = "Workload account role used by the application Lambda."
  value       = module.service_b_role.role_arn
}

output "tenant_kms_key_arns" {
  description = "Map of tenant key logical names to KMS key ARNs."
  value       = module.tenant_keys.key_arns
}

output "tenant_aliases" {
  description = "Map of tenant IDs to the alias format used by runtime session policies."
  value       = local.tenant_aliases
}

output "dynamodb_table_name" {
  description = "Workload-side DynamoDB table storing application ciphertext."
  value       = module.tenant_data.table_names["tenant_data"]
}

output "lambda_function_name" {
  description = "Sample workload Lambda implementing the assume-role and encrypt pattern."
  value       = module.service_b_lambda.function_name
}
