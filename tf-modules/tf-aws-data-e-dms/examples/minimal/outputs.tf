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

output "dms_vpc_role_arn" {
  description = "DMS VPC IAM role ARN."
  value       = module.dms.dms_vpc_role_arn
}
