# =============================================================================
# tf-aws-cloudwatch — AWS Backup Failure Alarms
#
# Monitors AWS Backup jobs across all resource types (EC2, RDS, EFS, DynamoDB,
# S3, Aurora, FSx, Storage Gateway).
#
# Creates 3 alarms when enabled = true:
#   - NumberOfBackupJobsFailed  → backup job did not complete
#   - NumberOfRestoreJobsFailed → restore job failed (impacts RTO/RPO)
#   - NumberOfCopyJobsFailed    → cross-region/cross-account copy failed
#
# To enable: set backup_alarms = { enabled = true }
# To disable: set backup_alarms = {} (default) or { enabled = false }
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "backup_alarms" {
  description = <<-EOT
    AWS Backup failure alarm configuration.
    Set enabled = true to activate alarms for backup, restore, and copy job failures.
    period = 86400 means the alarm checks once per day (suitable for daily backup windows).
  EOT
  type = object({
    enabled                      = optional(bool, false)
    backup_job_failed_threshold  = optional(number, 1)
    restore_job_failed_threshold = optional(number, 1)
    copy_job_failed_threshold    = optional(number, 1)
    evaluation_periods           = optional(number, 1)
    period                       = optional(number, 86400) # 24h window
  })
  default = {}
}

# ── Backup Job Failed ─────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "backup_job_failed" {
  count = try(var.backup_alarms.enabled, false) ? 1 : 0

  alarm_name          = "${local.prefix}-backup-job-failed"
  alarm_description   = "AWS Backup: one or more backup jobs FAILED. Check AWS Backup console → Jobs → Backup jobs for resource details and error messages."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = try(var.backup_alarms.evaluation_periods, 1)
  metric_name         = "NumberOfBackupJobsFailed"
  namespace           = "AWS/Backup"
  period              = try(var.backup_alarms.period, 86400)
  statistic           = "Sum"
  threshold           = try(var.backup_alarms.backup_job_failed_threshold, 1)
  treat_missing_data  = "notBreaching"

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "backup" })
}

# ── Restore Job Failed ────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "backup_restore_failed" {
  count = try(var.backup_alarms.enabled, false) ? 1 : 0

  alarm_name          = "${local.prefix}-backup-restore-failed"
  alarm_description   = "AWS Backup: one or more restore jobs FAILED. Recovery may be impacted. Check Backup console → Jobs → Restore jobs."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = try(var.backup_alarms.evaluation_periods, 1)
  metric_name         = "NumberOfRestoreJobsFailed"
  namespace           = "AWS/Backup"
  period              = try(var.backup_alarms.period, 86400)
  statistic           = "Sum"
  threshold           = try(var.backup_alarms.restore_job_failed_threshold, 1)
  treat_missing_data  = "notBreaching"

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "backup" })
}

# ── Copy Job Failed ───────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "backup_copy_failed" {
  count = try(var.backup_alarms.enabled, false) ? 1 : 0

  alarm_name          = "${local.prefix}-backup-copy-failed"
  alarm_description   = "AWS Backup: one or more cross-region or cross-account copy jobs FAILED. DR copies may be out of date."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = try(var.backup_alarms.evaluation_periods, 1)
  metric_name         = "NumberOfCopyJobsFailed"
  namespace           = "AWS/Backup"
  period              = try(var.backup_alarms.period, 86400)
  statistic           = "Sum"
  threshold           = try(var.backup_alarms.copy_job_failed_threshold, 1)
  treat_missing_data  = "notBreaching"

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "backup" })
}
