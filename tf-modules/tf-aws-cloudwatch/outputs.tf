# =============================================================================
# tf-aws-cloudwatch — Outputs
# =============================================================================

# ── SNS ───────────────────────────────────────────────────────────────────────

output "sns_topic_arn" {
  description = "Effective SNS topic ARN (module-created or BYO)."
  value       = local.effective_sns_arn
}

output "sns_topic_name" {
  description = "SNS topic name. Null if BYO topic was supplied."
  value       = var.create_sns_topic && var.sns_topic_arn == null ? try(aws_sns_topic.this[0].name, null) : null
}

# ── Generic / Anomaly / Composite Alarms ─────────────────────────────────────

output "metric_alarm_arns" {
  description = "Map of alarm key → ARN for all generic metric alarms."
  value       = { for k, v in aws_cloudwatch_metric_alarm.metric : k => v.arn }
}

output "anomaly_alarm_arns" {
  description = "Map of alarm key → ARN for anomaly detection alarms."
  value       = { for k, v in aws_cloudwatch_metric_alarm.anomaly : k => v.arn }
}

output "composite_alarm_arns" {
  description = "Map of composite alarm key → ARN."
  value       = { for k, v in aws_cloudwatch_composite_alarm.this : k => v.arn }
}

# ── Log Metric Filters ────────────────────────────────────────────────────────

output "log_metric_filter_names" {
  description = "Map of filter key → filter name."
  value       = { for k, v in aws_cloudwatch_log_metric_filter.this : k => v.name }
}

# ── ASG Alarms ────────────────────────────────────────────────────────────────

output "asg_cpu_high_alarm_arns" {
  description = "Map of ASG name → CPU high alarm ARN."
  value       = { for k, v in aws_cloudwatch_metric_alarm.asg_cpu_high : k => v.arn }
}

output "asg_cpu_low_alarm_arns" {
  description = "Map of ASG name → CPU low alarm ARN."
  value       = { for k, v in aws_cloudwatch_metric_alarm.asg_cpu_low : k => v.arn }
}

# ── Backup Alarms ─────────────────────────────────────────────────────────────

output "backup_job_failed_alarm_arn" {
  description = "Backup job failed alarm ARN. Null when backup_alarms.enabled = false."
  value       = try(var.backup_alarms.enabled, false) ? try(aws_cloudwatch_metric_alarm.backup_job_failed[0].arn, null) : null
}

output "backup_restore_failed_alarm_arn" {
  description = "Backup restore failed alarm ARN."
  value       = try(var.backup_alarms.enabled, false) ? try(aws_cloudwatch_metric_alarm.backup_restore_failed[0].arn, null) : null
}

output "backup_copy_failed_alarm_arn" {
  description = "Backup copy failed alarm ARN."
  value       = try(var.backup_alarms.enabled, false) ? try(aws_cloudwatch_metric_alarm.backup_copy_failed[0].arn, null) : null
}

# ── RDS Alarms ────────────────────────────────────────────────────────────────

output "rds_cpu_alarm_arns" {
  description = "Map of RDS logical key → CPU alarm ARN."
  value       = { for k, v in aws_cloudwatch_metric_alarm.rds_cpu : k => v.arn }
}

output "rds_storage_alarm_arns" {
  description = "Map of RDS logical key → storage alarm ARN."
  value       = { for k, v in aws_cloudwatch_metric_alarm.rds_storage : k => v.arn }
}

# ── API Gateway Alarms ────────────────────────────────────────────────────────

output "apigw_5xx_alarm_arns" {
  description = "Map of API Gateway logical key → 5xx alarm ARN."
  value       = { for k, v in aws_cloudwatch_metric_alarm.apigw_5xx : k => v.arn }
}

output "apigw_latency_alarm_arns" {
  description = "Map of API Gateway logical key → latency p99 alarm ARN."
  value       = { for k, v in aws_cloudwatch_metric_alarm.apigw_latency : k => v.arn }
}

# ── ECS Alarms ────────────────────────────────────────────────────────────────

output "ecs_cpu_alarm_arns" {
  description = "Map of ECS logical key → CPU alarm ARN."
  value       = { for k, v in aws_cloudwatch_metric_alarm.ecs_cpu : k => v.arn }
}

output "ecs_memory_alarm_arns" {
  description = "Map of ECS logical key → memory alarm ARN."
  value       = { for k, v in aws_cloudwatch_metric_alarm.ecs_memory : k => v.arn }
}

# ── ALB Alarms ────────────────────────────────────────────────────────────────

output "alb_5xx_alarm_arns" {
  description = "Map of ALB logical key → 5xx alarm ARN."
  value       = { for k, v in aws_cloudwatch_metric_alarm.alb_5xx : k => v.arn }
}

output "alb_unhealthy_alarm_arns" {
  description = "Map of ALB logical key → unhealthy host alarm ARN."
  value       = { for k, v in aws_cloudwatch_metric_alarm.alb_unhealthy : k => v.arn }
}

# ── ElastiCache Alarms ────────────────────────────────────────────────────────

output "elasticache_cpu_alarm_arns" {
  description = "Map of ElastiCache logical key → CPU alarm ARN."
  value       = { for k, v in aws_cloudwatch_metric_alarm.elasticache_cpu : k => v.arn }
}

output "elasticache_evictions_alarm_arns" {
  description = "Map of ElastiCache logical key → evictions alarm ARN."
  value       = { for k, v in aws_cloudwatch_metric_alarm.elasticache_evictions : k => v.arn }
}

# ── ACM Certificate Alarms ────────────────────────────────────────────────────

output "acm_expiry_warning_alarm_arns" {
  description = "List of ACM certificate expiry WARNING alarm ARNs."
  value       = [for alarm in aws_cloudwatch_metric_alarm.acm_expiry_warning : alarm.arn]
}

output "acm_expiry_critical_alarm_arns" {
  description = "List of ACM certificate expiry CRITICAL alarm ARNs."
  value       = [for alarm in aws_cloudwatch_metric_alarm.acm_expiry_critical : alarm.arn]
}

# ── Synthetics ────────────────────────────────────────────────────────────────

output "canary_arns" {
  description = "Map of canary logical key → canary ARN."
  value       = { for k, v in aws_synthetics_canary.this : k => v.arn }
}

output "canary_alarm_arns" {
  description = "Map of canary logical key → failure alarm ARN."
  value       = { for k, v in aws_cloudwatch_metric_alarm.canary : k => v.arn }
}

# ── CloudTrail Event Rules ────────────────────────────────────────────────────

output "deletion_alert_rule_arns" {
  description = "Map of service → EventBridge rule ARN for deletion alerts."
  value       = { for k, v in aws_cloudwatch_event_rule.resource_deleted : k => v.arn }
}

output "stop_alert_rule_arns" {
  description = "Map of service → EventBridge rule ARN for stop alerts."
  value       = { for k, v in aws_cloudwatch_event_rule.resource_stopped : k => v.arn }
}

# ── Security Alert Rules ──────────────────────────────────────────────────────

output "security_rule_arns" {
  description = "Map of security EventBridge rule names → ARNs."
  value = merge(
    var.enable_security_alerts ? {
      root_usage        = try(aws_cloudwatch_event_rule.root_usage[0].arn, null)
      iam_user_change   = try(aws_cloudwatch_event_rule.iam_user_change[0].arn, null)
      iam_policy_change = try(aws_cloudwatch_event_rule.iam_policy_change[0].arn, null)
      security_group    = try(aws_cloudwatch_event_rule.security_group_change[0].arn, null)
      s3_policy_change  = try(aws_cloudwatch_event_rule.s3_policy_change[0].arn, null)
    } : {},
    var.enable_guardduty_alerts ? {
      guardduty_findings = try(aws_cloudwatch_event_rule.guardduty_findings[0].arn, null)
    } : {}
  )
}

# ── Cost Anomaly ──────────────────────────────────────────────────────────────

output "cost_anomaly_monitor_arn" {
  description = "Cost Anomaly Detection monitor ARN. Null if not enabled."
  value       = var.enable_cost_anomaly_detection ? try(aws_ce_anomaly_monitor.this[0].arn, null) : null
}

# ── Dashboard ─────────────────────────────────────────────────────────────────

output "dashboard_name" {
  description = "CloudWatch dashboard name. Null if create_dashboard = false."
  value       = var.create_dashboard ? try(aws_cloudwatch_dashboard.this[0].dashboard_name, null) : null
}

output "dashboard_url" {
  description = "Direct URL to the CloudWatch dashboard in the AWS Console."
  value       = var.create_dashboard ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${try(aws_cloudwatch_dashboard.this[0].dashboard_name, "")}" : null
}
