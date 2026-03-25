output "workgroup_ids" {
  description = "Map of workgroup key to workgroup ID."
  value       = module.athena.workgroup_ids
}

output "workgroup_arns" {
  description = "Map of workgroup key to workgroup ARN."
  value       = module.athena.workgroup_arns
}

output "workgroup_names" {
  description = "Map of workgroup key to workgroup name."
  value       = module.athena.workgroup_names
}

output "database_ids" {
  description = "Map of database key to Glue database ID."
  value       = module.athena.database_ids
}

output "named_query_ids" {
  description = "Map of named query key to named query ID."
  value       = module.athena.named_query_ids
}

output "data_catalog_arns" {
  description = "Map of data catalog key to data catalog ARN."
  value       = module.athena.data_catalog_arns
}

output "prepared_statement_ids" {
  description = "Map of prepared statement key to resource ID."
  value       = module.athena.prepared_statement_ids
}

output "capacity_reservation_arns" {
  description = "Map of capacity reservation key to ARN."
  value       = module.athena.capacity_reservation_arns
}

output "athena_analyst_role_arn" {
  description = "ARN of the Athena analyst IAM role."
  value       = module.athena.athena_analyst_role_arn
}

output "athena_admin_role_arn" {
  description = "ARN of the Athena admin IAM role."
  value       = module.athena.athena_admin_role_arn
}

output "athena_analyst_policy_json" {
  description = "Analyst IAM policy JSON — attach to application roles."
  value       = module.athena.athena_analyst_policy_json
  sensitive   = true
}

output "s3_results_policy_json" {
  description = "S3 results bucket access policy JSON."
  value       = module.athena.s3_results_policy_json
  sensitive   = true
}

output "query_templates" {
  description = "Pre-built SQL query templates."
  value       = module.athena.query_templates
}
