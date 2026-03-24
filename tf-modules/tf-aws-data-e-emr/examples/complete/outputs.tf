output "cluster_ids" {
  description = "Map of cluster name to EMR cluster ID."
  value       = module.emr.cluster_ids
}

output "cluster_arns" {
  description = "Map of cluster name to EMR cluster ARN."
  value       = module.emr.cluster_arns
}

output "cluster_master_public_dns" {
  description = "Map of cluster name to master node public DNS."
  value       = module.emr.cluster_master_public_dns
}

output "serverless_application_arns" {
  description = "Map of serverless application name to ARN."
  value       = module.emr.serverless_application_arns
}

output "studio_urls" {
  description = "Map of studio name to URL."
  value       = module.emr.studio_urls
}

output "emr_service_role_arn" {
  description = "EMR service role ARN."
  value       = module.emr.emr_service_role_arn
}

output "emr_instance_profile_arn" {
  description = "EMR EC2 instance profile ARN."
  value       = module.emr.emr_instance_profile_arn
}

output "emr_autoscaling_role_arn" {
  description = "EMR autoscaling role ARN."
  value       = module.emr.emr_autoscaling_role_arn
}
