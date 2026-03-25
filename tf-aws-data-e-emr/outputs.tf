output "cluster_ids" {
  description = "Map of cluster name to EMR cluster ID."
  value       = { for k, v in aws_emr_cluster.this : k => v.id }
}

output "cluster_arns" {
  description = "Map of cluster name to EMR cluster ARN."
  value       = { for k, v in aws_emr_cluster.this : k => v.arn }
}

output "cluster_master_public_dns" {
  description = "Map of cluster name to master node public DNS name."
  value       = { for k, v in aws_emr_cluster.this : k => v.master_public_dns }
}

output "serverless_application_arns" {
  description = "Map of application name to EMR Serverless application ARN."
  value       = { for k, v in aws_emrserverless_application.this : k => v.arn }
}

output "serverless_application_ids" {
  description = "Map of application name to EMR Serverless application ID."
  value       = { for k, v in aws_emrserverless_application.this : k => v.id }
}

output "security_configuration_names" {
  description = "Map of security configuration key to EMR security configuration name."
  value       = { for k, v in aws_emr_security_configuration.this : k => v.name }
}

output "studio_ids" {
  description = "Map of studio name to EMR Studio ID."
  value       = { for k, v in aws_emr_studio.this : k => v.id }
}

output "studio_urls" {
  description = "Map of studio name to EMR Studio URL."
  value       = { for k, v in aws_emr_studio.this : k => v.url }
}

output "emr_service_role_arn" {
  description = "ARN of the EMR service IAM role."
  value       = var.create_iam_role ? aws_iam_role.emr_service[0].arn : var.role_arn
}

output "emr_service_role_name" {
  description = "Name of the EMR service IAM role."
  value       = var.create_iam_role ? aws_iam_role.emr_service[0].name : null
}

output "emr_instance_profile_arn" {
  description = "ARN of the EMR EC2 instance profile."
  value       = var.create_iam_role ? aws_iam_instance_profile.emr_ec2[0].arn : var.instance_profile_arn
}

output "emr_instance_profile_name" {
  description = "Name of the EMR EC2 instance profile."
  value       = var.create_iam_role ? aws_iam_instance_profile.emr_ec2[0].name : null
}

output "emr_ec2_role_arn" {
  description = "ARN of the EMR EC2 instance IAM role."
  value       = var.create_iam_role ? aws_iam_role.emr_ec2[0].arn : null
}

output "emr_autoscaling_role_arn" {
  description = "ARN of the EMR autoscaling IAM role."
  value       = var.create_iam_role ? aws_iam_role.emr_autoscaling[0].arn : null
}

output "aws_region" {
  description = "AWS region where resources are deployed."
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID where resources are deployed."
  value       = data.aws_caller_identity.current.account_id
}
