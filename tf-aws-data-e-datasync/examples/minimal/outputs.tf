output "task_arns" {
  description = "DataSync task ARNs."
  value       = module.datasync.task_arns
}

output "datasync_role_arn" {
  description = "DataSync IAM role ARN."
  value       = module.datasync.datasync_role_arn
}
