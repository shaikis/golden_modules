output "cluster_ids" {
  description = "EMR cluster IDs."
  value       = module.emr.cluster_ids
}

output "emr_service_role_arn" {
  description = "EMR service role ARN."
  value       = module.emr.emr_service_role_arn
}

output "emr_instance_profile_arn" {
  description = "EMR EC2 instance profile ARN."
  value       = module.emr.emr_instance_profile_arn
}
