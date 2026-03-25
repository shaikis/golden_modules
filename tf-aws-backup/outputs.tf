output "iam_role_arn" {
  description = "Effective IAM role ARN used for backup operations (created or BYO)."
  value       = local.iam_role_arn
}

# ── SNS ──────────────────────────────────────────────────────────────────────
output "sns_topic_arn" {
  description = "Effective SNS topic ARN used for backup notifications (created or BYO)."
  value       = local.effective_sns_topic_arn
}

output "sns_topic_name" {
  description = "Name of the module-created SNS topic. Null if BYO or notifications disabled."
  value       = var.create_sns_topic && var.sns_topic_arn == null ? aws_sns_topic.this[0].name : null
}

output "vault_arns" {
  value = { for k, v in aws_backup_vault.this : k => v.arn }
}

output "plan_ids" {
  value = { for k, v in aws_backup_plan.this : k => v.id }
}

output "framework_arn" {
  value = try(aws_backup_framework.this[0].arn, null)
}

# ── CloudWatch Logs ───────────────────────────────────────────────────────────
output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name for backup events. Null if enable_cloudwatch_logs = false."
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.backup_events[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN for backup events."
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.backup_events[0].arn : null
}

output "cloudwatch_event_rule_arn" {
  description = "EventBridge rule ARN routing backup events to CloudWatch Logs."
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_event_rule.backup_all_events[0].arn : null
}

# ── CloudWatch Alarms ─────────────────────────────────────────────────────────
output "cloudwatch_alarm_backup_failed_arn" {
  description = "ARN of CloudWatch alarm for failed backup jobs."
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.backup_job_failed[0].arn : null
}

output "cloudwatch_alarm_copy_failed_arn" {
  description = "ARN of CloudWatch alarm for failed copy jobs."
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.copy_job_failed[0].arn : null
}

output "cloudwatch_alarm_restore_failed_arn" {
  description = "ARN of CloudWatch alarm for failed restore jobs."
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.restore_job_failed[0].arn : null
}

# ── CloudWatch Dashboard ──────────────────────────────────────────────────────
output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name. Null if create_cloudwatch_dashboard = false."
  value       = var.create_cloudwatch_dashboard ? aws_cloudwatch_dashboard.backup[0].dashboard_name : null
}

output "cloudwatch_dashboard_url" {
  description = "Direct URL to the CloudWatch dashboard in the AWS Console."
  value       = var.create_cloudwatch_dashboard ? "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${aws_cloudwatch_dashboard.backup[0].dashboard_name}" : null
}

# ── Metric Namespaces ─────────────────────────────────────────────────────────
output "custom_metric_namespace" {
  description = "CloudWatch custom metric namespace for log-based backup metrics."
  value       = var.enable_cloudwatch_logs ? "${local.name_prefix}/BackupMetrics" : null
}