############################################
# CLOUDWATCH ALARMS
# Alarms on BOTH native AWS/Backup metrics (always available)
# AND custom log-based metrics (when enable_cloudwatch_logs = true).
############################################

# Alarm: backup jobs failed (native AWS/Backup metric — no log group needed)
resource "aws_cloudwatch_metric_alarm" "backup_job_failed" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-backup-job-failed"
  alarm_description   = "AWS Backup: ${var.name} (${var.environment}) — backup jobs are failing"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfBackupJobsFailed"
  namespace           = "AWS/Backup"
  period              = 86400
  statistic           = "Sum"
  threshold           = var.backup_job_failed_threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = local.alarm_actions_list
  ok_actions    = local.alarm_actions_list

  tags = local.common_tags
}

# Alarm: copy jobs failed (native metric)
resource "aws_cloudwatch_metric_alarm" "copy_job_failed" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-copy-job-failed"
  alarm_description   = "AWS Backup: ${var.name} (${var.environment}) — cross-region/account copy jobs are failing"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfCopyJobsFailed"
  namespace           = "AWS/Backup"
  period              = 86400
  statistic           = "Sum"
  threshold           = var.copy_job_failed_threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = local.alarm_actions_list
  ok_actions    = local.alarm_actions_list

  tags = local.common_tags
}

# Alarm: restore jobs failed (native metric)
resource "aws_cloudwatch_metric_alarm" "restore_job_failed" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-restore-job-failed"
  alarm_description   = "AWS Backup: ${var.name} (${var.environment}) — restore jobs are failing"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfRestoreJobsFailed"
  namespace           = "AWS/Backup"
  period              = 86400
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = local.alarm_actions_list
  ok_actions    = local.alarm_actions_list

  tags = local.common_tags
}
