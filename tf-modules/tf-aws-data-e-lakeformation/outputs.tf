output "registered_location_arns" {
  description = "Map of registered S3 data lake location ARNs keyed by location name."
  value       = { for k, v in aws_lakeformation_resource.this : k => v.arn }
}

output "lf_tag_ids" {
  description = "Map of LF-Tag IDs keyed by tag key."
  value       = { for k, v in aws_lakeformation_lf_tag.this : k => v.id }
}

output "permission_ids" {
  description = "Map of Lake Formation permission IDs keyed by permission name."
  value       = { for k, v in aws_lakeformation_permissions.this : k => v.id }
}

output "lf_tag_policy_permission_ids" {
  description = "Map of LF-Tag policy permission IDs keyed by policy name."
  value       = { for k, v in aws_lakeformation_permissions.lf_tag_policy : k => v.id }
}

output "data_filter_ids" {
  description = "Map of data cell filter IDs keyed by filter name."
  value       = { for k, v in aws_lakeformation_data_cells_filter.this : k => v.id }
}

output "resource_lf_tag_ids" {
  description = "Map of resource LF-tag assignment IDs keyed by assignment name."
  value       = { for k, v in aws_lakeformation_resource_lf_tags.this : k => v.id }
}

output "lakeformation_role_arn" {
  description = "ARN of the Lake Formation IAM service role."
  value       = local.effective_role_arn
}

output "lakeformation_role_name" {
  description = "Name of the Lake Formation IAM service role."
  value       = var.create_iam_role ? try(aws_iam_role.lakeformation[0].name, null) : null
}

output "data_lake_settings_catalog_id" {
  description = "Catalog ID associated with the Lake Formation data lake settings."
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region where Lake Formation resources are deployed."
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID in which Lake Formation resources are deployed."
  value       = data.aws_caller_identity.current.account_id
}
