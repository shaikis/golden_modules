# ────────────────────────────────────────────────────────────────────────────
# Locals
# ────────────────────────────────────────────────────────────────────────────
locals {
  prefix = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  tags = merge({
    Name        = var.name
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
  }, var.tags)

  # ── IAM Role resolution ──────────────────────────────────────────────────
  # Precedence: var.iam_role_arn (BYO) > module-created role
  #
  # Scenarios:
  #   create_iam_role = true  + iam_role_arn = null  → CREATE new role (default)
  #   create_iam_role = false + iam_role_arn = ARN   → USE existing role (BYO)
  #   create_iam_role = false + iam_role_arn = null  → ERROR (caught by validation below)
  iam_role_arn = var.iam_role_arn != null ? var.iam_role_arn : (
    var.create_iam_role ? aws_iam_role.restore[0].arn : null
  )

  # ── SNS Topic resolution ─────────────────────────────────────────────────
  # Precedence: var.sns_topic_arn (BYO) > module-created topic > null (no notifications)
  #
  # Scenarios:
  #   create_sns_topic = true  + sns_topic_arn = null → CREATE new topic (auto-create)
  #   create_sns_topic = false + sns_topic_arn = ARN  → USE existing topic (BYO)
  #   create_sns_topic = false + sns_topic_arn = null → null (no notifications)
  effective_sns_topic_arn = var.sns_topic_arn != null ? var.sns_topic_arn : (
    var.create_sns_topic && var.sns_topic_arn == null ? aws_sns_topic.restore[0].arn : null
  )
}

# ────────────────────────────────────────────────────────────────────────────
# IAM Role for Restore Operations
# ────────────────────────────────────────────────────────────────────────────
resource "aws_iam_role" "restore" {
  # Only create when user has NOT supplied an existing role ARN
  count = var.create_iam_role && var.iam_role_arn == null ? 1 : 0

  name = "${local.prefix}-restore-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags

  lifecycle {
    precondition {
      condition     = var.create_iam_role || var.iam_role_arn != null
      error_message = "Either set create_iam_role = true (default) to auto-create an IAM role, or provide an existing iam_role_arn."
    }
  }
}

# Core restore policy
resource "aws_iam_role_policy_attachment" "restore_core" {
  count      = var.create_iam_role && var.iam_role_arn == null ? 1 : 0
  role       = aws_iam_role.restore[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# EC2 instance restore policy
resource "aws_iam_role_policy_attachment" "restore_ec2" {
  count      = var.create_iam_role && var.iam_role_arn == null && var.enable_ec2_restore ? 1 : 0
  role       = aws_iam_role.restore[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# S3 restore policy
resource "aws_iam_role_policy_attachment" "restore_s3" {
  count      = var.create_iam_role && var.iam_role_arn == null && var.enable_s3_restore ? 1 : 0
  role       = aws_iam_role.restore[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
}

# Inline policy for RDS, EFS, DynamoDB, FSx restore permissions
resource "aws_iam_role_policy" "restore_extended" {
  count = var.create_iam_role && var.iam_role_arn == null ? 1 : 0
  name  = "${local.prefix}-restore-extended"
  role  = aws_iam_role.restore[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      var.enable_rds_restore ? [{
        Sid    = "RDSRestore"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:CreateDBInstance",
          "rds:CreateDBCluster",
          "rds:RestoreDBInstanceFromDBSnapshot",
          "rds:RestoreDBInstanceToPointInTime",
          "rds:RestoreDBClusterFromSnapshot",
          "rds:RestoreDBClusterToPointInTime",
          "rds:CreateDBSubnetGroup",
          "rds:DescribeDBSnapshots",
          "rds:DescribeDBClusterSnapshots",
          "rds:AddTagsToResource",
          "rds:ListTagsForResource",
        ]
        Resource = ["*"]
      }] : [],
      var.enable_efs_restore ? [{
        Sid    = "EFSRestore"
        Effect = "Allow"
        Action = [
          "elasticfilesystem:CreateFilesystem",
          "elasticfilesystem:DescribeFilesystems",
          "elasticfilesystem:CreateMountTarget",
          "elasticfilesystem:DescribeMountTargets",
          "elasticfilesystem:TagResource",
          "elasticfilesystem:Restore",
        ]
        Resource = ["*"]
      }] : [],
      var.enable_fsx_restore ? [{
        Sid    = "FSxRestore"
        Effect = "Allow"
        Action = [
          "fsx:CreateFileSystemFromBackup",
          "fsx:DescribeFileSystems",
          "fsx:DescribeBackups",
          "fsx:TagResource",
        ]
        Resource = ["*"]
      }] : [],
      [{
        Sid    = "CommonRestore"
        Effect = "Allow"
        Action = [
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeInternetGateways",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:Decrypt",
          "kms:CreateGrant",
          "iam:PassRole",
          "tag:GetResources",
        ]
        Resource = ["*"]
      }]
    )
  })
}

# ────────────────────────────────────────────────────────────────────────────
# SNS Topic for Restore Notifications
# ────────────────────────────────────────────────────────────────────────────
resource "aws_sns_topic" "restore" {
  # Only create when user has NOT supplied an existing topic ARN
  count             = var.create_sns_topic && var.sns_topic_arn == null ? 1 : 0
  name              = "${local.prefix}-restore-notifications"
  kms_master_key_id = var.sns_kms_key_id
  tags              = local.tags
}

resource "aws_sns_topic_policy" "restore" {
  count  = var.create_sns_topic && var.sns_topic_arn == null ? 1 : 0
  arn    = aws_sns_topic.restore[0].arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowBackupPublish"
      Effect = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action   = "sns:Publish"
      Resource = aws_sns_topic.restore[0].arn
    }]
  })
}

# ────────────────────────────────────────────────────────────────────────────
# CloudWatch Alarms for Restore Failures
# ────────────────────────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "restore_job_failed" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.prefix}-restore-job-failed"
  alarm_description   = "Triggers when AWS Backup restore jobs fail in ${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.restore_job_evaluation_periods
  metric_name         = "NumberOfRestoreJobsFailed"
  namespace           = "AWS/Backup"
  period              = var.restore_job_period
  statistic           = "Sum"
  threshold           = var.restore_job_failed_threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = length(var.alarm_actions) > 0 ? var.alarm_actions : (
    local.effective_sns_topic_arn != null ? [local.effective_sns_topic_arn] : []
  )

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "restore_job_expired" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.prefix}-restore-job-expired"
  alarm_description   = "Triggers when AWS Backup restore jobs expire (did not complete) in ${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.restore_job_evaluation_periods
  metric_name         = "NumberOfRestoreJobsExpired"
  namespace           = "AWS/Backup"
  period              = var.restore_job_period
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = length(var.alarm_actions) > 0 ? var.alarm_actions : (
    local.effective_sns_topic_arn != null ? [local.effective_sns_topic_arn] : []
  )

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "restore_testing_job_failed" {
  count = var.create_cloudwatch_alarms && length(var.restore_testing_plans) > 0 ? 1 : 0

  alarm_name          = "${local.prefix}-restore-test-failed"
  alarm_description   = "Triggers when automated restore testing jobs fail in ${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.restore_job_evaluation_periods
  metric_name         = "NumberOfRestoreTestingJobsFailed"
  namespace           = "AWS/Backup"
  period              = var.restore_job_period
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = length(var.alarm_actions) > 0 ? var.alarm_actions : (
    local.effective_sns_topic_arn != null ? [local.effective_sns_topic_arn] : []
  )

  tags = local.tags
}

# ────────────────────────────────────────────────────────────────────────────
# Restore Testing Plans
# ────────────────────────────────────────────────────────────────────────────
resource "aws_backup_restore_testing_plan" "this" {
  for_each = var.restore_testing_plans

  name = "${local.prefix}-${each.key}-restore-test"

  recovery_point_selection {
    algorithm             = each.value.algorithm
    recovery_point_types  = each.value.recovery_point_types
    include_vaults        = each.value.include_vaults
    exclude_vaults        = length(each.value.exclude_vaults) > 0 ? each.value.exclude_vaults : null
    selection_window_days = each.value.selection_window_days
  }

  schedule_expression          = each.value.schedule_expression
  schedule_expression_timezone = each.value.schedule_expression_timezone
  start_window_hours           = each.value.start_window_hours

  tags = merge(local.tags, each.value.tags)
}

# ────────────────────────────────────────────────────────────────────────────
# Restore Testing Selections
# ────────────────────────────────────────────────────────────────────────────
resource "aws_backup_restore_testing_selection" "this" {
  for_each = var.restore_testing_selections

  name                      = "${local.prefix}-${each.key}"
  restore_testing_plan_name = aws_backup_restore_testing_plan.this[each.value.restore_testing_plan_key].name
  protected_resource_type   = each.value.protected_resource_type

  iam_role_arn = each.value.iam_role_arn != null ? each.value.iam_role_arn : local.iam_role_arn

  protected_resource_arns    = length(each.value.protected_resource_arns) > 0 ? each.value.protected_resource_arns : null
  restore_metadata_overrides = length(each.value.restore_metadata_overrides) > 0 ? each.value.restore_metadata_overrides : null
  validation_window_hours    = each.value.validation_window_hours

  dynamic "protected_resource_conditions" {
    for_each = each.value.protected_resource_conditions != null ? [each.value.protected_resource_conditions] : []
    content {
      dynamic "string_equals" {
        for_each = protected_resource_conditions.value.string_equals
        content {
          key   = string_equals.value.key
          value = string_equals.value.value
        }
      }
      dynamic "string_not_equals" {
        for_each = protected_resource_conditions.value.string_not_equals
        content {
          key   = string_not_equals.value.key
          value = string_not_equals.value.value
        }
      }
    }
  }
}

############################################
# CLOUDWATCH LOGS
# AWS Backup does not write restore logs natively.
# EventBridge captures aws.backup restore events → CloudWatch Log Group.
############################################

# Log Group for restore events
resource "aws_cloudwatch_log_group" "restore_events" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = "/aws/restore/${local.prefix}/events"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_arn
  tags              = local.tags
}

# Resource policy allowing EventBridge to write to the log group
resource "aws_cloudwatch_log_resource_policy" "restore_events" {
  count       = var.enable_cloudwatch_logs ? 1 : 0
  policy_name = "${local.prefix}-restore-events-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowEventBridgePut"
      Effect = "Allow"
      Principal = {
        Service = ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
      }
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.restore_events[0].arn}:*"
    }]
  })
}

# EventBridge rule — capture restore and restore-testing events
resource "aws_cloudwatch_event_rule" "restore_events" {
  count       = var.enable_cloudwatch_logs ? 1 : 0
  name        = "${local.prefix}-restore-events"
  description = "Capture AWS Backup restore events for ${var.name} (${var.environment}) → CloudWatch Logs"

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = [
      "Restore Job State Change",
      "Recovery Point State Change",
    ]
  })

  tags = local.tags
}

# Route EventBridge restore events → CloudWatch Log Group
resource "aws_cloudwatch_event_target" "restore_logs" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  rule  = aws_cloudwatch_event_rule.restore_events[0].name
  arn   = aws_cloudwatch_log_group.restore_events[0].arn
}

############################################
# CLOUDWATCH LOG METRIC FILTERS
############################################

# Metric: restore jobs FAILED
resource "aws_cloudwatch_log_metric_filter" "restore_job_failed" {
  count          = var.enable_cloudwatch_logs ? 1 : 0
  name           = "${local.prefix}-restore-failed"
  log_group_name = aws_cloudwatch_log_group.restore_events[0].name

  pattern = "{ $.source = \"aws.backup\" && $.detail-type = \"Restore Job State Change\" && $.detail.status = \"FAILED\" }"

  metric_transformation {
    name          = "RestoreJobsFailed"
    namespace     = "${local.prefix}/RestoreMetrics"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# Metric: restore jobs COMPLETED successfully
resource "aws_cloudwatch_log_metric_filter" "restore_job_completed" {
  count          = var.enable_cloudwatch_logs ? 1 : 0
  name           = "${local.prefix}-restore-completed"
  log_group_name = aws_cloudwatch_log_group.restore_events[0].name

  pattern = "{ $.source = \"aws.backup\" && $.detail-type = \"Restore Job State Change\" && $.detail.status = \"COMPLETED\" }"

  metric_transformation {
    name          = "RestoreJobsCompleted"
    namespace     = "${local.prefix}/RestoreMetrics"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# Metric: restore jobs RUNNING (in progress)
resource "aws_cloudwatch_log_metric_filter" "restore_job_running" {
  count          = var.enable_cloudwatch_logs ? 1 : 0
  name           = "${local.prefix}-restore-running"
  log_group_name = aws_cloudwatch_log_group.restore_events[0].name

  pattern = "{ $.source = \"aws.backup\" && $.detail-type = \"Restore Job State Change\" && $.detail.status = \"RUNNING\" }"

  metric_transformation {
    name          = "RestoreJobsRunning"
    namespace     = "${local.prefix}/RestoreMetrics"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# Metric: restore duration (in seconds) for completed jobs
resource "aws_cloudwatch_log_metric_filter" "restore_job_duration" {
  count          = var.enable_cloudwatch_logs ? 1 : 0
  name           = "${local.prefix}-restore-duration"
  log_group_name = aws_cloudwatch_log_group.restore_events[0].name

  pattern = "{ $.source = \"aws.backup\" && $.detail-type = \"Restore Job State Change\" && $.detail.status = \"COMPLETED\" }"

  metric_transformation {
    name          = "RestoreJobDurationSeconds"
    namespace     = "${local.prefix}/RestoreMetrics"
    value         = "$.detail.percentDone"
    default_value = "0"
    unit          = "Seconds"
  }
}

############################################
# CLOUDWATCH ALARMS (log-metric based)
############################################

resource "aws_cloudwatch_metric_alarm" "restore_failed_log_based" {
  count = var.enable_cloudwatch_logs && var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.prefix}-restore-failed-log"
  alarm_description   = "Restore jobs are failing — detected via CloudWatch Log metric filter"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RestoreJobsFailed"
  namespace           = "${local.prefix}/RestoreMetrics"
  period              = 86400
  statistic           = "Sum"
  threshold           = var.restore_job_failed_threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = length(var.alarm_actions) > 0 ? var.alarm_actions : (
    local.effective_sns_topic_arn != null ? [local.effective_sns_topic_arn] : []
  )
  ok_actions = length(var.alarm_actions) > 0 ? var.alarm_actions : (
    local.effective_sns_topic_arn != null ? [local.effective_sns_topic_arn] : []
  )

  tags = local.tags
}

############################################
# CLOUDWATCH DASHBOARD
############################################

resource "aws_cloudwatch_dashboard" "restore" {
  count          = var.create_cloudwatch_dashboard ? 1 : 0
  dashboard_name = coalesce(var.dashboard_name, "${local.prefix}-restore-dashboard")

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x = 0; y = 0; width = 24; height = 1
        properties = {
          markdown = "# AWS Backup Restore Dashboard — ${var.name} (${var.environment})"
        }
      },
      {
        type   = "metric"
        x = 0; y = 1; width = 8; height = 6
        properties = {
          title   = "Restore Jobs Status (24h)"
          view    = "timeSeries"
          stacked = false
          period  = 86400
          stat    = "Sum"
          metrics = [
            ["AWS/Backup", "NumberOfRestoreJobsCompleted", { label = "Completed", color = "#2ca02c" }],
            ["AWS/Backup", "NumberOfRestoreJobsFailed",    { label = "Failed",    color = "#d62728" }],
            ["AWS/Backup", "NumberOfRestoreJobsExpired",   { label = "Expired",   color = "#ff7f0e" }],
          ]
        }
      },
      {
        type   = "metric"
        x = 8; y = 1; width = 8; height = 6
        properties = {
          title   = "Restore Testing Jobs (24h)"
          view    = "timeSeries"
          stacked = false
          period  = 86400
          stat    = "Sum"
          metrics = [
            ["AWS/Backup", "NumberOfRestoreTestingJobsCompleted", { label = "Test Completed", color = "#2ca02c" }],
            ["AWS/Backup", "NumberOfRestoreTestingJobsFailed",    { label = "Test Failed",    color = "#d62728" }],
          ]
        }
      },
      {
        type   = "metric"
        x = 16; y = 1; width = 8; height = 6
        properties = {
          title   = "Restore Alarms"
          view    = "timeSeries"
          stacked = false
          period  = 3600
          stat    = "Maximum"
          metrics = var.create_cloudwatch_alarms ? [
            ["AWS/Backup", "NumberOfRestoreJobsFailed",  { label = "Failed Jobs" }],
            ["AWS/Backup", "NumberOfRestoreJobsExpired", { label = "Expired Jobs" }],
          ] : []
        }
      },
      {
        type   = "alarm"
        x = 0; y = 7; width = 12; height = 4
        properties = {
          title  = "Active Restore Alarms"
          alarms = var.create_cloudwatch_alarms ? [
            aws_cloudwatch_metric_alarm.restore_job_failed[0].arn,
            aws_cloudwatch_metric_alarm.restore_job_expired[0].arn,
          ] : []
        }
      },
      {
        type   = "log"
        x = 0; y = 11; width = 24; height = 8
        properties = {
          title   = "Recent Restore Events (Last 24h)"
          query   = var.enable_cloudwatch_logs ? "SOURCE '/aws/restore/${local.prefix}/events' | fields @timestamp, detail.status, detail.resourceType, detail.restoreJobId | sort @timestamp desc | limit 50" : "# Enable enable_cloudwatch_logs = true to see restore events here"
          view    = "table"
        }
      }
    ]
  })
}
