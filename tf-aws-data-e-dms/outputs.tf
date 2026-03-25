# ---------------------------------------------------------------------------
# Replication instance outputs
# ---------------------------------------------------------------------------

output "replication_instance_arns" {
  description = "Map of replication instance key to ARN."
  value       = { for k, v in aws_dms_replication_instance.this : k => v.replication_instance_arn }
}

output "replication_instance_ids" {
  description = "Map of replication instance key to replication instance ID."
  value       = { for k, v in aws_dms_replication_instance.this : k => v.replication_instance_id }
}

# ---------------------------------------------------------------------------
# Endpoint outputs
# ---------------------------------------------------------------------------

output "endpoint_arns" {
  description = "Map of endpoint key to ARN."
  value       = { for k, v in aws_dms_endpoint.this : k => v.endpoint_arn }
}

output "endpoint_ids" {
  description = "Map of endpoint key to endpoint ID."
  value       = { for k, v in aws_dms_endpoint.this : k => v.endpoint_id }
}

# ---------------------------------------------------------------------------
# Task outputs
# ---------------------------------------------------------------------------

output "task_arns" {
  description = "Map of task key to replication task ARN."
  value       = { for k, v in aws_dms_replication_task.this : k => v.replication_task_arn }
}

output "task_ids" {
  description = "Map of task key to replication task ID."
  value       = { for k, v in aws_dms_replication_task.this : k => v.replication_task_id }
}

# ---------------------------------------------------------------------------
# IAM outputs
# ---------------------------------------------------------------------------

output "dms_vpc_role_arn" {
  description = "ARN of the dms-vpc-role IAM role. Empty string when create_iam_roles = false."
  value       = var.create_iam_roles ? aws_iam_role.dms_vpc_role[0].arn : ""
}

output "dms_logs_role_arn" {
  description = "ARN of the dms-cloudwatch-logs-role IAM role. Empty string when create_iam_roles = false."
  value       = var.create_iam_roles ? aws_iam_role.dms_cloudwatch_logs_role[0].arn : ""
}

output "dms_s3_role_arn" {
  description = "ARN of the DMS S3 access role. Empty string when create_iam_roles = false."
  value       = var.create_iam_roles ? aws_iam_role.dms_s3_role[0].arn : ""
}

# ---------------------------------------------------------------------------
# Certificate outputs
# ---------------------------------------------------------------------------

output "certificate_arns" {
  description = "Map of certificate key to ARN."
  value       = { for k, v in aws_dms_certificate.this : k => v.certificate_arn }
}

# ---------------------------------------------------------------------------
# Event subscription outputs
# ---------------------------------------------------------------------------

output "event_subscription_arns" {
  description = "Map of event subscription key to ARN."
  value       = { for k, v in aws_dms_event_subscription.this : k => v.arn }
}

# ---------------------------------------------------------------------------
# Subnet group outputs
# ---------------------------------------------------------------------------

output "subnet_group_ids" {
  description = "Map of subnet group key to replication subnet group ID."
  value       = { for k, v in aws_dms_replication_subnet_group.this : k => v.id }
}

# ---------------------------------------------------------------------------
# Alarm outputs
# ---------------------------------------------------------------------------

output "alarm_arns" {
  description = "Map of alarm names to ARNs for all CloudWatch alarms created."
  value = var.create_alarms ? merge(
    { for k, v in aws_cloudwatch_metric_alarm.cdc_latency_source : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.cdc_latency_target : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.cdc_incoming_changes : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.full_load_throughput_rows_target : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.table_errors : k => v.arn },
  ) : {}
}

# ---------------------------------------------------------------------------
# Convenience outputs
# ---------------------------------------------------------------------------

output "aws_region" {
  description = "AWS region where resources are deployed."
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID where resources are deployed."
  value       = data.aws_caller_identity.current.account_id
}
