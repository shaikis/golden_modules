output "file_system_id" {
  description = "ID of the EFS file system"
  value       = var.create ? aws_efs_file_system.this[0].id : null
}

output "file_system_arn" {
  description = "ARN of the EFS file system"
  value       = var.create ? aws_efs_file_system.this[0].arn : null
}

output "dns_name" {
  description = "DNS name of the EFS file system (use in mount commands)"
  value       = var.create ? aws_efs_file_system.this[0].dns_name : null
}

output "availability_zone_name" {
  description = "Availability Zone name for One Zone EFS, null for Regional EFS."
  value       = var.create ? aws_efs_file_system.this[0].availability_zone_name : null
}

output "mount_target_ids" {
  description = "Map of subnet_id => mount_target_id"
  value       = { for k, v in aws_efs_mount_target.this : k => v.id }
}

output "mount_target_dns_names" {
  description = "Map of subnet_id => mount_target DNS name (AZ-specific mount endpoint)"
  value       = { for k, v in aws_efs_mount_target.this : k => v.mount_target_dns_name }
}

output "access_point_ids" {
  description = "Map of access_point_key => access_point_id"
  value       = { for k, v in aws_efs_access_point.this : k => v.id }
}

output "access_point_arns" {
  description = "Map of access_point_key => access_point_arn"
  value       = { for k, v in aws_efs_access_point.this : k => v.arn }
}

output "security_group_id" {
  description = "ID of the auto-created EFS security group (null if create_security_group = false)"
  value       = var.create && var.create_security_group ? aws_security_group.efs[0].id : null
}

output "replication_destination_file_system_id" {
  description = "Destination file system ID for the legacy/default replication configuration when present, otherwise null."
  value       = try(aws_efs_replication_configuration.this["default"].destination[0].file_system_id, null)
}

output "replication_destination_file_system_ids" {
  description = "Map of replication key => destination file system ID."
  value       = { for key, replication in aws_efs_replication_configuration.this : key => replication.destination[0].file_system_id }
}

output "replication_configurations" {
  description = "Map of replication key => normalized replication details and observed destination status."
  value = {
    for key, replication in aws_efs_replication_configuration.this : key => {
      source_file_system_id      = replication.source_file_system_id
      source_file_system_arn     = replication.source_file_system_arn
      source_file_system_region  = replication.source_file_system_region
      destination_file_system_id = replication.destination[0].file_system_id
      destination_status         = replication.destination[0].status
      destination_region         = try(local.normalized_replications[key].destination_region, null)
      existing_destination       = try(local.normalized_replications[key].destination_file_system_id, null) != null
    }
  }
}

output "file_system_policy_id" {
  description = "ID of the EFS file system policy attachment, null when not configured."
  value       = var.create && var.file_system_policy != null ? aws_efs_file_system_policy.this[0].id : null
}
