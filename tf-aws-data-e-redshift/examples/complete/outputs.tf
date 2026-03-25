output "cluster_ids" {
  description = "Provisioned cluster identifiers."
  value       = module.redshift.cluster_ids
}

output "cluster_arns" {
  description = "Provisioned cluster ARNs."
  value       = module.redshift.cluster_arns
}

output "cluster_endpoints" {
  description = "Provisioned cluster endpoints."
  value       = module.redshift.cluster_endpoints
}

output "cluster_dns_names" {
  description = "Provisioned cluster DNS names."
  value       = module.redshift.cluster_dns_names
}

output "serverless_namespace_arns" {
  description = "Serverless namespace ARNs."
  value       = module.redshift.serverless_namespace_arns
}

output "serverless_workgroup_arns" {
  description = "Serverless workgroup ARNs."
  value       = module.redshift.serverless_workgroup_arns
}

output "serverless_workgroup_endpoints" {
  description = "Serverless workgroup endpoints."
  value       = module.redshift.serverless_workgroup_endpoints
}

output "subnet_group_names" {
  description = "Subnet group names."
  value       = module.redshift.subnet_group_names
}

output "parameter_group_names" {
  description = "Parameter group names."
  value       = module.redshift.parameter_group_names
}

output "redshift_role_arn" {
  description = "Redshift service IAM role ARN."
  value       = module.redshift.redshift_role_arn
}

output "scheduled_action_role_arn" {
  description = "Scheduled action IAM role ARN."
  value       = module.redshift.scheduled_action_role_arn
}

output "snapshot_schedule_arns" {
  description = "Snapshot schedule ARNs."
  value       = module.redshift.snapshot_schedule_arns
}

output "alarm_arns" {
  description = "CloudWatch alarm ARNs."
  value       = module.redshift.alarm_arns
}

output "aws_region" {
  description = "Deployment AWS region."
  value       = module.redshift.aws_region
}

output "aws_account_id" {
  description = "Deployment AWS account ID."
  value       = module.redshift.aws_account_id
}
