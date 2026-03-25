############################################
# CLOUDWATCH LOGS
# AWS Backup does not write logs natively.
# EventBridge captures aws.backup events → CloudWatch Log Group.
############################################

# Log Group for all backup events
resource "aws_cloudwatch_log_group" "backup_events" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = "/aws/backup/${local.name_prefix}/events"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_arn
  tags              = local.common_tags
}

# Resource policy allowing EventBridge to write to the log group
resource "aws_cloudwatch_log_resource_policy" "backup_events" {
  count       = var.enable_cloudwatch_logs ? 1 : 0
  policy_name = "${local.name_prefix}-backup-events-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowEventBridgePut"
      Effect = "Allow"
      Principal = {
        Service = ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
      }
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.backup_events[0].arn}:*"
    }]
  })
}

# EventBridge rule — capture ALL aws.backup events
resource "aws_cloudwatch_event_rule" "backup_all_events" {
  count       = var.enable_cloudwatch_logs ? 1 : 0
  name        = "${local.name_prefix}-backup-all-events"
  description = "Capture all AWS Backup events for ${var.name} (${var.environment}) → CloudWatch Logs"

  event_pattern = jsonencode({
    source = ["aws.backup"]
    detail-type = [
      "Backup Job State Change",
      "Copy Job State Change",
      "Restore Job State Change",
      "Recovery Point State Change",
    ]
  })

  tags = local.common_tags
}

# Route EventBridge events → CloudWatch Log Group
resource "aws_cloudwatch_event_target" "backup_logs" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  rule  = aws_cloudwatch_event_rule.backup_all_events[0].name
  arn   = aws_cloudwatch_log_group.backup_events[0].arn
}

############################################
# CLOUDWATCH LOG METRIC FILTERS
# Create custom metrics from the event logs.
############################################

# Metric: backup jobs that FAILED
resource "aws_cloudwatch_log_metric_filter" "backup_job_failed" {
  count          = var.enable_cloudwatch_logs ? 1 : 0
  name           = "${local.name_prefix}-backup-job-failed"
  log_group_name = aws_cloudwatch_log_group.backup_events[0].name

  # Match EventBridge events where backup job state = FAILED
  pattern = "{ $.source = \"aws.backup\" && $.detail-type = \"Backup Job State Change\" && $.detail.state = \"FAILED\" }"

  metric_transformation {
    name          = "BackupJobsFailed"
    namespace     = "${local.name_prefix}/BackupMetrics"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# Metric: backup jobs that COMPLETED
resource "aws_cloudwatch_log_metric_filter" "backup_job_completed" {
  count          = var.enable_cloudwatch_logs ? 1 : 0
  name           = "${local.name_prefix}-backup-job-completed"
  log_group_name = aws_cloudwatch_log_group.backup_events[0].name

  pattern = "{ $.source = \"aws.backup\" && $.detail-type = \"Backup Job State Change\" && $.detail.state = \"COMPLETED\" }"

  metric_transformation {
    name          = "BackupJobsCompleted"
    namespace     = "${local.name_prefix}/BackupMetrics"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# Metric: copy jobs that FAILED (cross-region/cross-account copies)
resource "aws_cloudwatch_log_metric_filter" "copy_job_failed" {
  count          = var.enable_cloudwatch_logs ? 1 : 0
  name           = "${local.name_prefix}-copy-job-failed"
  log_group_name = aws_cloudwatch_log_group.backup_events[0].name

  pattern = "{ $.source = \"aws.backup\" && $.detail-type = \"Copy Job State Change\" && $.detail.state = \"FAILED\" }"

  metric_transformation {
    name          = "CopyJobsFailed"
    namespace     = "${local.name_prefix}/BackupMetrics"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# Metric: copy jobs that COMPLETED
resource "aws_cloudwatch_log_metric_filter" "copy_job_completed" {
  count          = var.enable_cloudwatch_logs ? 1 : 0
  name           = "${local.name_prefix}-copy-job-completed"
  log_group_name = aws_cloudwatch_log_group.backup_events[0].name

  pattern = "{ $.source = \"aws.backup\" && $.detail-type = \"Copy Job State Change\" && $.detail.state = \"COMPLETED\" }"

  metric_transformation {
    name          = "CopyJobsCompleted"
    namespace     = "${local.name_prefix}/BackupMetrics"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# Metric: restore jobs that FAILED
resource "aws_cloudwatch_log_metric_filter" "restore_job_failed" {
  count          = var.enable_cloudwatch_logs ? 1 : 0
  name           = "${local.name_prefix}-restore-job-failed"
  log_group_name = aws_cloudwatch_log_group.backup_events[0].name

  pattern = "{ $.source = \"aws.backup\" && $.detail-type = \"Restore Job State Change\" && $.detail.state = \"FAILED\" }"

  metric_transformation {
    name          = "RestoreJobsFailed"
    namespace     = "${local.name_prefix}/BackupMetrics"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# Metric: restore jobs that COMPLETED
resource "aws_cloudwatch_log_metric_filter" "restore_job_completed" {
  count          = var.enable_cloudwatch_logs ? 1 : 0
  name           = "${local.name_prefix}-restore-job-completed"
  log_group_name = aws_cloudwatch_log_group.backup_events[0].name

  pattern = "{ $.source = \"aws.backup\" && $.detail-type = \"Restore Job State Change\" && $.detail.state = \"COMPLETED\" }"

  metric_transformation {
    name          = "RestoreJobsCompleted"
    namespace     = "${local.name_prefix}/BackupMetrics"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}
