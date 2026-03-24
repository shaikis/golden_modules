# ── SNS ───────────────────────────────────────────────────────────────────────

output "sns_topic_arn" {
  description = "Effective SNS topic ARN used for alarm notifications."
  value       = module.cloudwatch.sns_topic_arn
}

output "sns_topic_name" {
  description = "SNS topic name. Null when a BYO topic ARN was supplied."
  value       = module.cloudwatch.sns_topic_name
}

# ── Metric Alarms ─────────────────────────────────────────────────────────────

output "metric_alarm_arns" {
  description = "Map of alarm logical key → ARN for all generic metric alarms."
  value       = module.cloudwatch.metric_alarm_arns
}

output "anomaly_alarm_arns" {
  description = "Map of alarm logical key → ARN for anomaly detection alarms."
  value       = module.cloudwatch.anomaly_alarm_arns
}

output "composite_alarm_arns" {
  description = "Map of composite alarm logical key → ARN."
  value       = module.cloudwatch.composite_alarm_arns
}

# ── ASG Alarms ────────────────────────────────────────────────────────────────

output "asg_cpu_high_alarm_arns" {
  description = "Map of ASG name → CPU high alarm ARN."
  value       = module.cloudwatch.asg_cpu_high_alarm_arns
}

output "asg_cpu_low_alarm_arns" {
  description = "Map of ASG name → CPU low alarm ARN."
  value       = module.cloudwatch.asg_cpu_low_alarm_arns
}

# ── Backup Alarms ─────────────────────────────────────────────────────────────

output "backup_job_failed_alarm_arn" {
  description = "Backup job failed alarm ARN. Null when backup alarms are disabled."
  value       = module.cloudwatch.backup_job_failed_alarm_arn
}

output "backup_restore_failed_alarm_arn" {
  description = "Backup restore failed alarm ARN."
  value       = module.cloudwatch.backup_restore_failed_alarm_arn
}

output "backup_copy_failed_alarm_arn" {
  description = "Backup copy job failed alarm ARN."
  value       = module.cloudwatch.backup_copy_failed_alarm_arn
}

# ── Synthetics ────────────────────────────────────────────────────────────────

output "canary_arns" {
  description = "Map of canary logical key → canary ARN."
  value       = module.cloudwatch.canary_arns
}

output "canary_alarm_arns" {
  description = "Map of canary logical key → failure alarm ARN."
  value       = module.cloudwatch.canary_alarm_arns
}

# ── Dashboard ─────────────────────────────────────────────────────────────────

output "dashboard_name" {
  description = "CloudWatch dashboard name. Null when create_dashboard = false."
  value       = module.cloudwatch.dashboard_name
}

output "dashboard_url" {
  description = "Direct link to the CloudWatch dashboard in the AWS console."
  value       = module.cloudwatch.dashboard_url
}

# ── Log Metric Filters ────────────────────────────────────────────────────────

output "log_metric_filter_names" {
  description = "Map of filter logical key → CloudWatch metric filter name."
  value       = module.cloudwatch.log_metric_filter_names
}
