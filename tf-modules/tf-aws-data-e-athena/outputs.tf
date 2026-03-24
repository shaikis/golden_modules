output "workgroup_ids" {
  description = "Map of workgroup key to workgroup ID."
  value       = { for k, v in aws_athena_workgroup.this : k => v.id }
}

output "workgroup_arns" {
  description = "Map of workgroup key to workgroup ARN."
  value       = { for k, v in aws_athena_workgroup.this : k => v.arn }
}

output "workgroup_names" {
  description = "Map of workgroup key to workgroup name."
  value       = { for k, v in aws_athena_workgroup.this : k => v.name }
}

output "database_ids" {
  description = "Map of database key to Glue database ID."
  value       = { for k, v in aws_athena_database.this : k => v.id }
}

output "named_query_ids" {
  description = "Map of named query key to named query ID."
  value       = { for k, v in aws_athena_named_query.this : k => v.id }
}

output "data_catalog_arns" {
  description = "Map of data catalog key to data catalog ARN."
  value       = { for k, v in aws_athena_data_catalog.this : k => v.arn }
}

output "prepared_statement_ids" {
  description = "Map of prepared statement key to resource ID."
  value       = { for k, v in aws_athena_prepared_statement.this : k => v.id }
}

output "capacity_reservation_arns" {
  description = "Map of capacity reservation key to ARN."
  value       = { for k, v in aws_athena_capacity_reservation.this : k => v.arn }
}

output "athena_analyst_role_arn" {
  description = "ARN of the Athena analyst IAM role."
  value       = aws_iam_role.athena_analyst.arn
}

output "athena_admin_role_arn" {
  description = "ARN of the Athena admin IAM role."
  value       = aws_iam_role.athena_admin.arn
}

output "athena_analyst_policy_json" {
  description = "JSON of the Athena analyst IAM policy — attach to application IAM roles."
  value       = data.aws_iam_policy_document.athena_analyst.json
}

output "s3_results_policy_json" {
  description = "JSON of the S3 results bucket access policy."
  value       = data.aws_iam_policy_document.s3_results.json
}

output "query_templates" {
  description = "Pre-built SQL query template strings (use as a reference; replace {table})."
  value       = local.query_templates
}
