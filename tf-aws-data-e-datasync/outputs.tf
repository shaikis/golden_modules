# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "s3_location_arns" {
  description = "Map of S3 location name to DataSync location ARN."
  value       = { for k, v in aws_datasync_location_s3.this : k => v.arn }
}

output "efs_location_arns" {
  description = "Map of EFS location name to DataSync location ARN."
  value       = { for k, v in aws_datasync_location_efs.this : k => v.arn }
}

output "fsx_windows_location_arns" {
  description = "Map of FSx Windows location name to DataSync location ARN."
  value       = { for k, v in aws_datasync_location_fsx_windows_file_system.this : k => v.arn }
}

output "fsx_lustre_location_arns" {
  description = "Map of FSx Lustre location name to DataSync location ARN."
  value       = { for k, v in aws_datasync_location_fsx_lustre_file_system.this : k => v.arn }
}

output "nfs_location_arns" {
  description = "Map of NFS location name to DataSync location ARN."
  value       = { for k, v in aws_datasync_location_nfs.this : k => v.arn }
}

output "smb_location_arns" {
  description = "Map of SMB location name to DataSync location ARN."
  value       = { for k, v in aws_datasync_location_smb.this : k => v.arn }
}

output "hdfs_location_arns" {
  description = "Map of HDFS location name to DataSync location ARN."
  value       = { for k, v in aws_datasync_location_hdfs.this : k => v.arn }
}

output "object_storage_location_arns" {
  description = "Map of object storage location name to DataSync location ARN."
  value       = { for k, v in aws_datasync_location_object_storage.this : k => v.arn }
}

output "task_arns" {
  description = "Map of task name to DataSync task ARN."
  value       = { for k, v in aws_datasync_task.this : k => v.arn }
}

output "task_ids" {
  description = "Map of task name to DataSync task ID."
  value       = { for k, v in aws_datasync_task.this : k => v.id }
}

output "agent_arns" {
  description = "Map of agent name to DataSync agent ARN."
  value       = { for k, v in aws_datasync_agent.this : k => v.arn }
}

output "datasync_role_arn" {
  description = "ARN of the DataSync IAM role (null when create_iam_role = false and role_arn not set)."
  value       = local.effective_role_arn
}

output "alarm_arns" {
  description = "Map of alarm name to CloudWatch alarm ARN."
  value = var.create_alarms ? merge(
    { for k, v in aws_cloudwatch_metric_alarm.bytes_transferred : "${k}-bytes-transferred-low" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.files_verified_failed : "${k}-files-verified-failed" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.task_execution_errors : "${k}-execution-errors" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.files_not_transferred : "${k}-files-not-transferred" => v.arn },
  ) : {}
}
