output "agent_instance_ids" {
  description = "EC2 instance IDs of the DataSync agents."
  value       = { for k, v in aws_instance.agent : k => v.id }
}

output "agent_private_ips" {
  description = "Private IPs of the DataSync agent EC2 instances."
  value       = { for k, v in aws_instance.agent : k => v.private_ip }
}

output "agent_arns" {
  description = "Registered DataSync agent ARNs."
  value       = { for k, v in aws_datasync_agent.this : k => v.arn }
}

output "agent_arns_ssm_params" {
  description = "SSM Parameter Store paths where agent ARNs are stored."
  value       = { for k, v in aws_ssm_parameter.agent_ip : k => "/datasync/${local.name}/agents/${k}/arn" }
}

output "s3_location_arns" {
  value = { for k, v in aws_datasync_location_s3.this : k => v.arn }
}

output "efs_location_arns" {
  value = { for k, v in aws_datasync_location_efs.this : k => v.arn }
}

output "nfs_location_arns" {
  value = { for k, v in aws_datasync_location_nfs.this : k => v.arn }
}

output "smb_location_arns" {
  value = { for k, v in aws_datasync_location_smb.this : k => v.arn }
}

output "fsx_windows_location_arns" {
  value = { for k, v in aws_datasync_location_fsx_windows_file_system.this : k => v.arn }
}

output "fsx_lustre_location_arns" {
  value = { for k, v in aws_datasync_location_fsx_lustre_file_system.this : k => v.arn }
}

output "fsx_openzfs_location_arns" {
  value = { for k, v in aws_datasync_location_fsx_openzfs_file_system.this : k => v.arn }
}

output "object_storage_location_arns" {
  value = { for k, v in aws_datasync_location_object_storage.this : k => v.arn }
}

output "hdfs_location_arns" {
  value = { for k, v in aws_datasync_location_hdfs.this : k => v.arn }
}

output "task_arns" {
  description = "DataSync task ARNs."
  value       = { for k, v in aws_datasync_task.this : k => v.arn }
}

output "task_ids" {
  description = "DataSync task IDs."
  value       = { for k, v in aws_datasync_task.this : k => v.id }
}
