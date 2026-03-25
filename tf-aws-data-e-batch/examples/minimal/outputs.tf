output "compute_environment_arns" {
  description = "Batch compute environment ARNs."
  value       = module.batch.compute_environment_arns
}

output "job_queue_arns" {
  description = "Batch job queue ARNs."
  value       = module.batch.job_queue_arns
}

output "job_definition_arns" {
  description = "Batch job definition ARNs."
  value       = module.batch.job_definition_arns
}

output "batch_service_role_arn" {
  description = "Batch service role ARN."
  value       = module.batch.batch_service_role_arn
}
