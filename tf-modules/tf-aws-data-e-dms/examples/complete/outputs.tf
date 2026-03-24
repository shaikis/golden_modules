output "replication_instance_arns" {
  description = "DMS replication instance ARNs."
  value       = module.dms.replication_instance_arns
}

output "endpoint_arns" {
  description = "DMS endpoint ARNs."
  value       = module.dms.endpoint_arns
}

output "task_arns" {
  description = "DMS replication task ARNs."
  value       = module.dms.task_arns
}

output "task_ids" {
  description = "DMS replication task IDs."
  value       = module.dms.task_ids
}

output "dms_vpc_role_arn" {
  description = "DMS VPC IAM role ARN."
  value       = module.dms.dms_vpc_role_arn
}

output "dms_logs_role_arn" {
  description = "DMS CloudWatch logs IAM role ARN."
  value       = module.dms.dms_logs_role_arn
}

output "dms_s3_role_arn" {
  description = "DMS S3 access IAM role ARN."
  value       = module.dms.dms_s3_role_arn
}

output "alarm_arns" {
  description = "All CloudWatch alarm ARNs."
  value       = module.dms.alarm_arns
}

output "event_subscription_arns" {
  description = "DMS event subscription ARNs."
  value       = module.dms.event_subscription_arns
}
