output "compute_environment_arns" {
  description = "Map of compute environment name to ARN."
  value       = { for k, v in aws_batch_compute_environment.this : k => v.arn }
}

output "compute_environment_ecs_cluster_arns" {
  description = "Map of compute environment name to the underlying ECS cluster ARN."
  value       = { for k, v in aws_batch_compute_environment.this : k => v.ecs_cluster_arn }
}

output "job_queue_arns" {
  description = "Map of job queue name to ARN."
  value       = { for k, v in aws_batch_job_queue.this : k => v.arn }
}

output "job_definition_arns" {
  description = "Map of job definition name to ARN (latest revision)."
  value       = { for k, v in aws_batch_job_definition.this : k => v.arn }
}

output "job_definition_revision_arns" {
  description = "Map of job definition name to ARN with revision number."
  value       = { for k, v in aws_batch_job_definition.this : k => v.arn_prefix }
}

output "scheduling_policy_arns" {
  description = "Map of scheduling policy name to ARN."
  value       = { for k, v in aws_batch_scheduling_policy.this : k => v.arn }
}

output "batch_service_role_arn" {
  description = "ARN of the AWS Batch service IAM role."
  value       = var.create_iam_role ? aws_iam_role.batch_service[0].arn : var.role_arn
}

output "batch_service_role_name" {
  description = "Name of the AWS Batch service IAM role."
  value       = var.create_iam_role ? aws_iam_role.batch_service[0].name : null
}

output "ec2_instance_role_arn" {
  description = "ARN of the EC2 instance IAM role for Batch compute environments."
  value       = var.create_iam_role ? aws_iam_role.batch_ec2_instance[0].arn : null
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile for Batch EC2 compute environments."
  value       = var.create_iam_role ? aws_iam_instance_profile.batch_ec2[0].arn : null
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution IAM role for Fargate containers."
  value       = var.create_iam_role ? aws_iam_role.ecs_task_execution[0].arn : null
}

output "job_role_arn" {
  description = "ARN of the Batch job IAM role for container access to AWS services."
  value       = var.create_iam_role ? aws_iam_role.batch_job[0].arn : null
}

output "spot_fleet_role_arn" {
  description = "ARN of the Spot fleet IAM role."
  value       = var.create_iam_role ? aws_iam_role.spot_fleet[0].arn : null
}

output "aws_region" {
  description = "AWS region where resources are deployed."
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID where resources are deployed."
  value       = data.aws_caller_identity.current.account_id
}
