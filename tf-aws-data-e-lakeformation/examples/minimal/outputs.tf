output "registered_location_arns" {
  description = "Registered S3 data lake location ARNs."
  value       = module.lakeformation.registered_location_arns
}

output "lakeformation_role_arn" {
  description = "ARN of the Lake Formation IAM service role."
  value       = module.lakeformation.lakeformation_role_arn
}
