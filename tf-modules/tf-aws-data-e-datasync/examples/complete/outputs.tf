output "s3_location_arns" {
  description = "DataSync S3 location ARNs."
  value       = module.datasync.s3_location_arns
}

output "efs_location_arns" {
  description = "DataSync EFS location ARNs."
  value       = module.datasync.efs_location_arns
}

output "nfs_location_arns" {
  description = "DataSync NFS location ARNs."
  value       = module.datasync.nfs_location_arns
}

output "task_arns" {
  description = "DataSync task ARNs."
  value       = module.datasync.task_arns
}

output "task_ids" {
  description = "DataSync task IDs."
  value       = module.datasync.task_ids
}

output "datasync_role_arn" {
  description = "DataSync IAM role ARN."
  value       = module.datasync.datasync_role_arn
}

output "alarm_arns" {
  description = "CloudWatch alarm ARNs."
  value       = module.datasync.alarm_arns
}
