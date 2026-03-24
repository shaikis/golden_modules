############################################
# LOCALS (Naming + Tags)
############################################
locals {
  name_prefix = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  common_tags = merge(
    {
      Name        = var.name
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
    },
    var.tags
  )

  # IAM: if existing ARN is provided → use it; else use the module-created role
  # Precedence: var.iam_role_arn (BYO) > module-created role
  iam_role_arn = var.iam_role_arn != null ? var.iam_role_arn : (
    var.create_iam_role ? aws_iam_role.backup[0].arn : null
  )

  # SNS: if existing ARN is provided → use it; else use module-created topic; else null
  # Precedence: var.sns_topic_arn (BYO) > module-created topic > null (no notifications)
  effective_sns_topic_arn = var.sns_topic_arn != null ? var.sns_topic_arn : (
    var.create_sns_topic && var.sns_topic_arn == null ? aws_sns_topic.this[0].arn : null
  )
}

############################################
# IAM ROLE
# create_iam_role = true  + iam_role_arn = null → module creates new role  (default)
# create_iam_role = false + iam_role_arn = ARN  → use existing role (BYO from another module)
############################################
resource "aws_iam_role" "backup" {
  # Only create when user has NOT supplied an existing role ARN
  count = var.create_iam_role && var.iam_role_arn == null ? 1 : 0

  name = coalesce(var.iam_role_name, "${local.name_prefix}-backup-role")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  count      = var.create_iam_role && var.iam_role_arn == null ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  count      = var.create_iam_role && var.iam_role_arn == null ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_iam_role_policy_attachment" "s3_backup" {
  count      = var.create_iam_role && var.iam_role_arn == null && var.enable_s3_backup ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
}

resource "aws_iam_role_policy_attachment" "s3_restore" {
  count      = var.create_iam_role && var.iam_role_arn == null && var.enable_s3_backup ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
}

############################################
# SNS TOPIC (Module-Level)
# create_sns_topic = true  + sns_topic_arn = null → module creates new topic
# create_sns_topic = false + sns_topic_arn = ARN  → use existing topic (BYO)
# create_sns_topic = false + sns_topic_arn = null → no module-level notifications
############################################
resource "aws_sns_topic" "this" {
  count             = var.create_sns_topic && var.sns_topic_arn == null ? 1 : 0
  name              = "${local.name_prefix}-backup-notifications"
  kms_master_key_id = var.sns_kms_key_id
  tags              = local.common_tags
}

resource "aws_sns_topic_policy" "this" {
  count = var.create_sns_topic && var.sns_topic_arn == null ? 1 : 0
  arn   = aws_sns_topic.this[0].arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowBackupPublish"
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.this[0].arn
    }]
  })
}

############################################
# VAULTS
############################################
resource "aws_backup_vault" "this" {
  for_each = var.vaults

  name        = "${local.name_prefix}-${each.key}"
  kms_key_arn = each.value.kms_key_arn
  tags        = merge(local.common_tags, each.value.tags)
}

############################################
# VAULT POLICY
############################################
resource "aws_backup_vault_policy" "this" {
  for_each = {
    for k, v in var.vaults : k => v if v.policy != null
  }

  backup_vault_name = aws_backup_vault.this[each.key].name
  policy            = each.value.policy
}

############################################
# VAULT LOCK
############################################
resource "aws_backup_vault_lock_configuration" "this" {
  for_each = {
    for k, v in var.vaults : k => v if v.enable_vault_lock
  }

  backup_vault_name = aws_backup_vault.this[each.key].name

  changeable_for_days = each.value.vault_lock_changeable_for_days
  min_retention_days  = each.value.vault_lock_min_retention_days
  max_retention_days  = each.value.vault_lock_max_retention_days
}

############################################
# VAULT NOTIFICATIONS
# Priority: per-vault sns_topic_arn > module-level effective_sns_topic_arn
############################################
resource "aws_backup_vault_notifications" "this" {
  for_each = {
    for k, v in var.vaults : k => v
    if v.sns_topic_arn != null || local.effective_sns_topic_arn != null
  }

  backup_vault_name   = aws_backup_vault.this[each.key].name
  sns_topic_arn       = coalesce(each.value.sns_topic_arn, local.effective_sns_topic_arn)
  backup_vault_events = each.value.notification_events
}

############################################
# BACKUP PLANS
############################################
resource "aws_backup_plan" "this" {
  for_each = var.plans

  name = "${local.name_prefix}-${each.key}"

  dynamic "rule" {
    for_each = each.value.rules

    content {
      rule_name = rule.value.rule_name

      target_vault_name = coalesce(
        try(aws_backup_vault.this[rule.value.vault_key].name, null),
        rule.value.target_vault_name
      )

      schedule                     = rule.value.schedule
      schedule_expression_timezone = rule.value.schedule_expression_timezone
      start_window                 = rule.value.start_window
      completion_window            = rule.value.completion_window

      enable_continuous_backup = rule.value.enable_continuous_backup
      recovery_point_tags      = rule.value.recovery_point_tags

      dynamic "lifecycle" {
        for_each = rule.value.lifecycle != null ? [rule.value.lifecycle] : []
        content {
          cold_storage_after = lifecycle.value.cold_storage_after
          delete_after       = lifecycle.value.delete_after
        }
      }

      dynamic "copy_action" {
        for_each = rule.value.copy_actions
        content {
          destination_vault_arn = copy_action.value.destination_vault_arn

          dynamic "lifecycle" {
            for_each = copy_action.value.lifecycle != null ? [copy_action.value.lifecycle] : []
            content {
              cold_storage_after = lifecycle.value.cold_storage_after
              delete_after       = lifecycle.value.delete_after
            }
          }
        }
      }
    }
  }

  dynamic "advanced_backup_setting" {
    for_each = each.value.advanced_backup_settings
    content {
      resource_type  = advanced_backup_setting.value.resource_type
      backup_options = advanced_backup_setting.value.backup_options
    }
  }

  tags = merge(local.common_tags, each.value.tags)
}

############################################
# SELECTIONS
############################################
resource "aws_backup_selection" "this" {
  for_each = var.selections

  name    = "${local.name_prefix}-${each.key}"
  plan_id = aws_backup_plan.this[each.value.plan_key].id

  iam_role_arn = coalesce(
    each.value.iam_role_arn, # 1. per-selection override
    local.iam_role_arn       # 2. module-level (BYO or created)
  )

  resources     = each.value.resources
  not_resources = each.value.not_resources

  dynamic "selection_tag" {
    for_each = each.value.selection_tags
    content {
      type  = selection_tag.value.type
      key   = selection_tag.value.key
      value = selection_tag.value.value
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions != null ? [each.value.conditions] : []
    content {
      dynamic "string_equals" {
        for_each = condition.value.string_equals
        content {
          key   = string_equals.value.key
          value = string_equals.value.value
        }
      }

      dynamic "string_not_equals" {
        for_each = condition.value.string_not_equals
        content {
          key   = string_not_equals.value.key
          value = string_not_equals.value.value
        }
      }

      dynamic "string_like" {
        for_each = condition.value.string_like
        content {
          key   = string_like.value.key
          value = string_like.value.value
        }
      }

      dynamic "string_not_like" {
        for_each = condition.value.string_not_like
        content {
          key   = string_not_like.value.key
          value = string_not_like.value.value
        }
      }
    }
  }
}

############################################
# BACKUP FRAMEWORK
############################################
resource "aws_backup_framework" "this" {
  count = var.create_framework ? 1 : 0

  name        = "${local.name_prefix}-framework"
  description = var.framework_description

  dynamic "control" {
    for_each = var.framework_controls
    content {
      name = control.value.name

      dynamic "input_parameter" {
        for_each = control.value.input_parameters
        content {
          name  = input_parameter.value.name
          value = input_parameter.value.value
        }
      }
    }
  }

  tags = local.common_tags
}

############################################
# REPORT PLANS
############################################
resource "aws_backup_report_plan" "this" {
  for_each = var.report_plans

  name        = "${local.name_prefix}-${each.key}"
  description = each.value.description

  report_delivery_channel {
    s3_bucket_name = each.value.s3_bucket_name
    s3_key_prefix  = each.value.s3_key_prefix
    formats        = each.value.formats
  }

  report_setting {
    report_template = each.value.report_template
  }

  tags = merge(local.common_tags, each.value.tags)
}

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

############################################
# CLOUDWATCH ALARMS
# Alarms on BOTH native AWS/Backup metrics (always available)
# AND custom log-based metrics (when enable_cloudwatch_logs = true).
############################################

locals {
  alarm_actions_list = length(var.alarm_actions) > 0 ? var.alarm_actions : (
    local.effective_sns_topic_arn != null ? [local.effective_sns_topic_arn] : []
  )
}

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
