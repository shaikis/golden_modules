# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Standard Tables
# ---------------------------------------------------------------------------

output "table_arns" {
  description = "Map of table key to ARN."
  value       = { for k, v in aws_dynamodb_table.this : k => v.arn }
}

output "table_names" {
  description = "Map of table key to DynamoDB table name."
  value       = { for k, v in aws_dynamodb_table.this : k => v.name }
}

output "table_stream_arns" {
  description = "Map of table key to stream ARN (null if streams not enabled)."
  value = {
    for k, v in aws_dynamodb_table.this : k =>
    (v.stream_enabled ? v.stream_arn : null)
  }
}

output "table_ids" {
  description = "Map of table key to table ID."
  value       = { for k, v in aws_dynamodb_table.this : k => v.id }
}

# ---------------------------------------------------------------------------
# Global Tables
# ---------------------------------------------------------------------------

output "global_table_arns" {
  description = "Map of global table key to ARN."
  value       = { for k, v in aws_dynamodb_table.global : k => v.arn }
}

output "global_table_names" {
  description = "Map of global table key to table name."
  value       = { for k, v in aws_dynamodb_table.global : k => v.name }
}

output "global_table_stream_arns" {
  description = "Map of global table key to stream ARN."
  value       = { for k, v in aws_dynamodb_table.global : k => v.stream_arn }
}

# ---------------------------------------------------------------------------
# Auto Scaling
# ---------------------------------------------------------------------------

output "autoscaling_read_policy_arns" {
  description = "Map of table key to read auto-scaling policy ARN."
  value       = { for k, v in aws_appautoscaling_policy.table_read : k => v.arn }
}

output "autoscaling_write_policy_arns" {
  description = "Map of table key to write auto-scaling policy ARN."
  value       = { for k, v in aws_appautoscaling_policy.table_write : k => v.arn }
}

output "autoscaling_policy_arns" {
  description = "Combined map of all autoscaling policy ARNs (read and write)."
  value = merge(
    { for k, v in aws_appautoscaling_policy.table_read : "${k}_read" => v.arn },
    { for k, v in aws_appautoscaling_policy.table_write : "${k}_write" => v.arn },
    { for k, v in aws_appautoscaling_policy.gsi_read : "${k}_read" => v.arn },
    { for k, v in aws_appautoscaling_policy.gsi_write : "${k}_write" => v.arn }
  )
}

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------

output "backup_vault_arn" {
  description = "ARN of the AWS Backup vault."
  value       = var.create_backup_plan ? aws_backup_vault.this[0].arn : null
}

output "backup_vault_name" {
  description = "Name of the AWS Backup vault."
  value       = var.create_backup_plan ? aws_backup_vault.this[0].name : null
}

output "backup_plan_arn" {
  description = "ARN of the AWS Backup plan."
  value       = var.create_backup_plan ? aws_backup_plan.this[0].arn : null
}

output "backup_plan_id" {
  description = "ID of the AWS Backup plan."
  value       = var.create_backup_plan ? aws_backup_plan.this[0].id : null
}

# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------

output "read_only_role_arn" {
  description = "ARN of the read-only IAM role."
  value       = var.create_iam_roles ? aws_iam_role.read_only[0].arn : null
}

output "read_write_role_arn" {
  description = "ARN of the read-write IAM role."
  value       = var.create_iam_roles ? aws_iam_role.read_write[0].arn : null
}

output "admin_role_arn" {
  description = "ARN of the admin IAM role."
  value       = var.create_iam_roles ? aws_iam_role.admin[0].arn : null
}

output "stream_consumer_role_arn" {
  description = "ARN of the stream consumer IAM role (null if no streams enabled)."
  value = (
    var.create_iam_roles && length(local.all_table_stream_arns) > 0
    ? aws_iam_role.stream_consumer[0].arn
    : null
  )
}

output "read_only_policy_arn" {
  description = "ARN of the read-only IAM policy."
  value       = var.create_iam_roles ? aws_iam_policy.read_only[0].arn : null
}

output "read_write_policy_arn" {
  description = "ARN of the read-write IAM policy."
  value       = var.create_iam_roles ? aws_iam_policy.read_write[0].arn : null
}

output "read_only_policy_json" {
  description = "JSON of the read-only IAM policy (attach to application roles)."
  value       = var.create_iam_roles ? data.aws_iam_policy_document.read_only[0].json : null
}

output "read_write_policy_json" {
  description = "JSON of the read-write IAM policy (attach to application roles)."
  value       = var.create_iam_roles ? data.aws_iam_policy_document.read_write[0].json : null
}

output "per_user_isolation_policy_arn" {
  description = "ARN of the per-user data isolation policy."
  value       = var.create_iam_roles ? aws_iam_policy.per_user_isolation[0].arn : null
}

# ---------------------------------------------------------------------------
# CloudWatch Alarms
# ---------------------------------------------------------------------------

output "alarm_arns" {
  description = "Map of 'table_key/alarm_type' to CloudWatch alarm ARN."
  value = merge(
    { for k, v in aws_cloudwatch_metric_alarm.system_errors : "${k}/system_errors" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.user_errors : "${k}/user_errors" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.read_throttle : "${k}/read_throttle" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.write_throttle : "${k}/write_throttle" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.latency_get : "${k}/latency_get" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.latency_query : "${k}/latency_query" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.latency_put : "${k}/latency_put" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.consumed_read_capacity : "${k}/consumed_rcu" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.consumed_write_capacity : "${k}/consumed_wcu" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.gsi_build_progress : "${k}/gsi_progress" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.replication_latency : "${k}/replication_latency" => v.arn }
  )
}

# ---------------------------------------------------------------------------
# Kinesis Streaming
# ---------------------------------------------------------------------------

output "kinesis_streaming_destinations" {
  description = "Map of table key to Kinesis stream ARN."
  value       = { for k, v in aws_dynamodb_kinesis_streaming_destination.this : k => v.stream_arn }
}

# ---------------------------------------------------------------------------
# Contributor Insights
# ---------------------------------------------------------------------------

output "contributor_insights_tables" {
  description = "List of tables with Contributor Insights enabled."
  value       = [for k, v in aws_dynamodb_contributor_insights.table : v.table_name]
}
