output "registered_location_arns" {
  description = "Registered S3 data lake location ARNs."
  value       = module.lakeformation.registered_location_arns
}

output "lf_tag_ids" {
  description = "LF-Tag IDs."
  value       = module.lakeformation.lf_tag_ids
}

output "permission_ids" {
  description = "Lake Formation permission IDs."
  value       = module.lakeformation.permission_ids
}

output "data_filter_ids" {
  description = "Data cell filter IDs."
  value       = module.lakeformation.data_filter_ids
}

output "lakeformation_role_arn" {
  description = "ARN of the Lake Formation IAM service role."
  value       = module.lakeformation.lakeformation_role_arn
}

output "aws_account_id" {
  description = "AWS account ID."
  value       = module.lakeformation.aws_account_id
}

output "aws_region" {
  description = "AWS region."
  value       = module.lakeformation.aws_region
}
