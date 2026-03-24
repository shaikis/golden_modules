output "compute_environment_arns" {
  description = "Map of compute environment name to ARN."
  value       = module.batch.compute_environment_arns
}

output "job_queue_arns" {
  description = "Map of job queue name to ARN."
  value       = module.batch.job_queue_arns
}

output "job_definition_arns" {
  description = "Map of job definition name to ARN."
  value       = module.batch.job_definition_arns
}

output "scheduling_policy_arns" {
  description = "Map of scheduling policy name to ARN."
  value       = module.batch.scheduling_policy_arns
}

output "batch_service_role_arn" {
  description = "Batch service role ARN."
  value       = module.batch.batch_service_role_arn
}

output "ec2_instance_profile_arn" {
  description = "EC2 instance profile ARN."
  value       = module.batch.ec2_instance_profile_arn
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN."
  value       = module.batch.ecs_task_execution_role_arn
}

output "job_role_arn" {
  description = "Batch job role ARN."
  value       = module.batch.job_role_arn
}
