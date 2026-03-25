# -- IAM ---------------------------------------------------------------------
output "iam_role_arn" {
  description = "Effective IAM role ARN used for restore operations (module-created or BYO)."
  value       = local.iam_role_arn
}

output "iam_role_name" {
  description = "Name of the IAM role used for restore operations."
  value       = var.create_iam_role ? aws_iam_role.restore[0].name : null
}

# -- SNS ---------------------------------------------------------------------
output "sns_topic_arn" {
  description = "Effective SNS topic ARN for restore notifications (module-created or BYO). Null if notifications disabled."
  value       = local.effective_sns_topic_arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for restore notifications."
  value       = var.create_sns_topic ? aws_sns_topic.restore[0].name : null
}

# -- CloudWatch Alarms -------------------------------------------------------
output "cloudwatch_alarm_restore_failed_arn" {
  description = "ARN of the CloudWatch alarm for failed restore jobs."
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.restore_job_failed[0].arn : null
}

output "cloudwatch_alarm_restore_expired_arn" {
  description = "ARN of the CloudWatch alarm for expired restore jobs."
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.restore_job_expired[0].arn : null
}

output "cloudwatch_alarm_restore_testing_failed_arn" {
  description = "ARN of the CloudWatch alarm for failed restore testing jobs."
  value       = var.create_cloudwatch_alarms && length(var.restore_testing_plans) > 0 ? aws_cloudwatch_metric_alarm.restore_testing_job_failed[0].arn : null
}

# -- Restore Testing Plans ---------------------------------------------------
output "restore_testing_plan_names" {
  description = "Map of restore testing plan logical key to AWS plan name."
  value       = { for k, v in aws_backup_restore_testing_plan.this : k => v.name }
}

output "restore_testing_plan_arns" {
  description = "Map of restore testing plan logical key to ARN."
  value       = { for k, v in aws_backup_restore_testing_plan.this : k => v.arn }
}

# -- Restore Testing Selections ----------------------------------------------
output "restore_testing_selection_names" {
  description = "Map of restore testing selection logical key to AWS selection name."
  value       = { for k, v in aws_backup_restore_testing_selection.this : k => v.name }
}

# -- Restore Guidance --------------------------------------------------------
output "restore_guidance" {
  description = "CLI commands and console steps to manually trigger a restore job."
  value       = <<-EOT
    ─────────────────────────────────────────────────────────────
    AWS Backup Restore Reference
    ─────────────────────────────────────────────────────────────

    1. LIST RECOVERY POINTS (find what to restore from):
       aws backup list-recovery-points-by-backup-vault \
         --backup-vault-name <vault-name> \
         --query 'RecoveryPoints[*].{ARN:RecoveryPointArn,Date:CreationDate,Resource:ResourceArn}'

    2. GET RESTORE METADATA (parameters needed for restore):
       aws backup get-recovery-point-restore-metadata \
         --backup-vault-name <vault-name> \
         --recovery-point-arn <recovery-point-arn>

    3. START RESTORE JOB:
       aws backup start-restore-job \
         --recovery-point-arn <recovery-point-arn> \
         --iam-role-arn ${var.create_iam_role ? "$(terraform output -raw iam_role_arn)" : var.iam_role_arn != null ? var.iam_role_arn : "<iam-role-arn>"} \
         --metadata '{"key":"value"}'

    4. POINT-IN-TIME RESTORE (RDS/Aurora/S3):
       aws backup start-restore-job \
         --recovery-point-arn <continuous-recovery-point-arn> \
         --iam-role-arn <iam-role-arn> \
         --metadata '{"restoreType":"POINT_IN_TIME","targetTime":"2024-01-01T12:00:00Z"}'

    5. MONITOR RESTORE JOB:
       aws backup describe-restore-job --restore-job-id <job-id>
       aws backup list-restore-jobs --by-status RUNNING

    6. CROSS-REGION RESTORE:
       Add --region <target-region> to any of the above commands.
       The IAM role ARN: ${var.create_iam_role ? "use terraform output iam_role_arn in the target region" : var.iam_role_arn != null ? var.iam_role_arn : "<iam-role-arn>"}

    Resource-specific restore metadata examples:
      EC2 : {"instanceType":"t3.medium","availabilityZone":"us-east-1a","subnetId":"subnet-xxx","securityGroupIds":"sg-xxx"}
      RDS : {"DBInstanceIdentifier":"restored-db","AvailabilityZone":"us-east-1a","VpcId":"vpc-xxx","MultiAZ":"false"}
      Aurora: {"ClusterIdentifier":"restored-cluster","Engine":"aurora-mysql","AvailabilityZones":"[\"us-east-1a\"]"}
      EFS : {"newFileSystem":"true","CreationToken":"my-restore","PerformanceMode":"generalPurpose"}
      DynamoDB: {"targetTableName":"restored-table"}
      S3  : {"newBucket":"my-restored-bucket","SSEAlgorithm":"AES256"}
      EBS : {"availabilityZone":"us-east-1a"}
      FSx : {"fileSystemType":"LUSTRE","StorageCapacity":"1200","SubnetIds":"[\"subnet-xxx\"]"}
    ─────────────────────────────────────────────────────────────
  EOT
}

# ── CloudWatch Logs ───────────────────────────────────────────────────────────
output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name for restore events. Null if enable_cloudwatch_logs = false."
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.restore_events[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN for restore events."
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.restore_events[0].arn : null
}

output "cloudwatch_event_rule_arn" {
  description = "EventBridge rule ARN routing restore events to CloudWatch Logs."
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_event_rule.restore_events[0].arn : null
}

output "custom_metric_namespace" {
  description = "CloudWatch custom metric namespace for log-based restore metrics."
  value       = var.enable_cloudwatch_logs ? "${local.prefix}/RestoreMetrics" : null
}

# ── CloudWatch Dashboard ──────────────────────────────────────────────────────
output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name. Null if create_cloudwatch_dashboard = false."
  value       = var.create_cloudwatch_dashboard ? aws_cloudwatch_dashboard.restore[0].dashboard_name : null
}

output "cloudwatch_dashboard_url" {
  description = "Direct URL to the CloudWatch restore dashboard in AWS Console."
  value       = var.create_cloudwatch_dashboard ? "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${aws_cloudwatch_dashboard.restore[0].dashboard_name}" : null
}
