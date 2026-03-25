############################################
# CLOUDWATCH DASHBOARD
############################################
resource "aws_cloudwatch_dashboard" "backup" {
  count          = var.create_cloudwatch_dashboard ? 1 : 0
  dashboard_name = coalesce(var.dashboard_name, "${local.name_prefix}-backup-dashboard")

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# AWS Backup Dashboard — ${var.name} (${var.environment})"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "Backup Jobs (24h)"
          view    = "timeSeries"
          stacked = false
          period  = 86400
          stat    = "Sum"
          metrics = [
            ["AWS/Backup", "NumberOfBackupJobsCompleted", { label = "Completed", color = "#2ca02c" }],
            ["AWS/Backup", "NumberOfBackupJobsFailed", { label = "Failed", color = "#d62728" }],
            ["AWS/Backup", "NumberOfBackupJobsExpired", { label = "Expired", color = "#ff7f0e" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "Copy Jobs — Cross-Region/Account (24h)"
          view    = "timeSeries"
          stacked = false
          period  = 86400
          stat    = "Sum"
          metrics = [
            ["AWS/Backup", "NumberOfCopyJobsCompleted", { label = "Completed", color = "#2ca02c" }],
            ["AWS/Backup", "NumberOfCopyJobsFailed", { label = "Failed", color = "#d62728" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "Restore Jobs (24h)"
          view    = "timeSeries"
          stacked = false
          period  = 86400
          stat    = "Sum"
          metrics = [
            ["AWS/Backup", "NumberOfRestoreJobsCompleted", { label = "Completed", color = "#2ca02c" }],
            ["AWS/Backup", "NumberOfRestoreJobsFailed", { label = "Failed", color = "#d62728" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6
        properties = {
          title   = "Recovery Points in Vaults"
          view    = "timeSeries"
          stacked = true
          period  = 3600
          stat    = "Average"
          metrics = [
            ["AWS/Backup", "NumberOfRecoveryPointsCompleted", { label = "Recovery Points" }],
          ]
        }
      },
      {
        type   = "alarm"
        x      = 12
        y      = 7
        width  = 12
        height = 6
        properties = {
          title = "Backup Alarms"
          alarms = var.create_cloudwatch_alarms ? [
            aws_cloudwatch_metric_alarm.backup_job_failed[0].arn,
            aws_cloudwatch_metric_alarm.copy_job_failed[0].arn,
            aws_cloudwatch_metric_alarm.restore_job_failed[0].arn,
          ] : []
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 13
        width  = 24
        height = 8
        properties = {
          title  = "Recent Backup Events (Last 24h)"
          region = "us-east-1"
          query  = var.enable_cloudwatch_logs ? "SOURCE '/aws/backup/${local.name_prefix}/events' | fields @timestamp, detail.state, detail.resourceType, detail.backupJobId | sort @timestamp desc | limit 50" : "# Enable enable_cloudwatch_logs = true to see events here"
          view   = "table"
        }
      }
    ]
  })
}
