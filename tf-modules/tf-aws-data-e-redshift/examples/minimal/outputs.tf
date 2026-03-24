output "cluster_endpoints" {
  description = "Redshift cluster endpoints."
  value       = module.redshift.cluster_endpoints
}

output "cluster_arns" {
  description = "Redshift cluster ARNs."
  value       = module.redshift.cluster_arns
}

output "subnet_group_names" {
  description = "Subnet group names."
  value       = module.redshift.subnet_group_names
}

output "redshift_role_arn" {
  description = "Redshift IAM role ARN."
  value       = module.redshift.redshift_role_arn
}
