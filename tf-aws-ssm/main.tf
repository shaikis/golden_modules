locals {
  name_prefix = "${var.name}-${var.environment}"

  common_tags = merge(var.tags, {
    Name        = local.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

##############################################################################
# FEATURE 1: PARAMETER STORE
##############################################################################
resource "aws_ssm_parameter" "this" {
  for_each = var.parameters

  name            = each.key
  value           = each.value.value
  type            = each.value.type
  description     = each.value.description
  tier            = each.value.tier
  data_type       = each.value.data_type
  overwrite       = each.value.overwrite
  key_id          = each.value.type == "SecureString" ? var.kms_key_arn : null
  allowed_pattern = each.value.allowed_pattern

  tags = local.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

##############################################################################
# FEATURE 2: PATCH MANAGER
##############################################################################
resource "aws_ssm_patch_baseline" "this" {
  for_each = var.create_patch_baselines ? var.patch_baselines : {}

  name             = "${local.name_prefix}-${each.key}"
  description      = each.value.description
  operating_system = each.value.operating_system

  approved_patches                  = each.value.approved_patches
  approved_patches_compliance_level = "UNSPECIFIED"
  rejected_patches                  = each.value.rejected_patches
  rejected_patches_action           = length(each.value.rejected_patches) > 0 ? "BLOCK" : "ALLOW_AS_DEPENDENCY"

  dynamic "approval_rule" {
    for_each = each.value.approval_rules
    content {
      approve_after_days  = approval_rule.value.approve_after_days
      compliance_level    = approval_rule.value.compliance_level
      enable_non_security = approval_rule.value.enable_non_security

      dynamic "patch_filter" {
        for_each = approval_rule.value.patch_filters
        content {
          key    = patch_filter.value.key
          values = patch_filter.value.values
        }
      }
    }
  }

  dynamic "global_filter" {
    for_each = each.value.global_filters
    content {
      key    = global_filter.value.key
      values = global_filter.value.values
    }
  }

  tags = local.common_tags
}

resource "aws_ssm_default_patch_baseline" "this" {
  for_each = {
    for k, v in var.patch_baselines : k => v
    if var.create_patch_baselines && v.default_baseline
  }

  baseline_id      = aws_ssm_patch_baseline.this[each.key].id
  operating_system = each.value.operating_system
}

resource "aws_ssm_patch_group" "this" {
  for_each = var.create_patch_baselines ? var.patch_groups : {}

  baseline_id = aws_ssm_patch_baseline.this[each.value].id
  patch_group = each.key
}

##############################################################################
# FEATURE 3: MAINTENANCE WINDOWS
##############################################################################
resource "aws_iam_role" "maintenance_window" {
  count = length(var.maintenance_windows) > 0 ? 1 : 0

  name = "${local.name_prefix}-ssm-maint-window-role"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ssm.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "maintenance_window" {
  count      = length(var.maintenance_windows) > 0 ? 1 : 0
  role       = aws_iam_role.maintenance_window[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}

resource "aws_ssm_maintenance_window" "this" {
  for_each = var.maintenance_windows

  name                       = "${local.name_prefix}-${each.key}"
  description                = each.value.description
  schedule                   = each.value.schedule
  duration                   = each.value.duration
  cutoff                     = each.value.cutoff
  enabled                    = each.value.enabled
  schedule_timezone          = each.value.schedule_timezone
  allow_unassociated_targets = each.value.allow_unassociated_targets

  tags = local.common_tags
}

resource "aws_ssm_maintenance_window_target" "this" {
  for_each = {
    for item in flatten([
      for win_key, win in var.maintenance_windows : [
        for idx, target in win.targets : {
          key     = "${win_key}-${idx}"
          win_key = win_key
          idx     = idx
          target  = target
        }
      ]
    ]) : item.key => item
  }

  window_id     = aws_ssm_maintenance_window.this[each.value.win_key].id
  name          = "${local.name_prefix}-${each.value.win_key}-target-${each.value.idx}"
  resource_type = "INSTANCE"

  targets {
    key    = each.value.target.key
    values = each.value.target.values
  }
}

resource "aws_ssm_maintenance_window_task" "this" {
  for_each = {
    for item in flatten([
      for win_key, win in var.maintenance_windows : [
        for task_key, task in win.tasks : {
          key      = "${win_key}--${task_key}"
          win_key  = win_key
          task_key = task_key
          task     = task
        }
      ]
    ]) : item.key => item
  }

  window_id       = aws_ssm_maintenance_window.this[each.value.win_key].id
  name            = "${local.name_prefix}-${each.value.task_key}"
  task_type       = each.value.task.task_type
  task_arn        = each.value.task.document_name
  priority        = each.value.task.priority
  max_concurrency = each.value.task.max_concurrency
  max_errors      = each.value.task.max_errors
  service_role_arn = coalesce(
    each.value.task.service_role_arn,
    try(aws_iam_role.maintenance_window[0].arn, null)
  )

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.this["${each.value.win_key}-0"].id]
  }

  dynamic "task_invocation_parameters" {
    for_each = each.value.task.task_type == "RUN_COMMAND" ? [1] : []
    content {
      run_command_parameters {
        dynamic "parameter" {
          for_each = each.value.task.parameters
          content {
            name   = parameter.key
            values = parameter.value
          }
        }
      }
    }
  }

  dynamic "task_invocation_parameters" {
    for_each = each.value.task.task_type == "AUTOMATION" ? [1] : []
    content {
      automation_parameters {
        document_version = each.value.task.document_version
        dynamic "parameter" {
          for_each = each.value.task.parameters
          content {
            name   = parameter.key
            values = parameter.value
          }
        }
      }
    }
  }
}

##############################################################################
# FEATURE 4: SESSION MANAGER
##############################################################################
resource "aws_cloudwatch_log_group" "session_manager" {
  count = var.enable_session_manager && var.session_manager_cloudwatch_log_group != null ? 1 : 0

  name              = var.session_manager_cloudwatch_log_group
  retention_in_days = var.session_manager_log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.common_tags
}

resource "aws_ssm_document" "session_manager_prefs" {
  count = var.enable_session_manager ? 1 : 0

  name          = "SSM-SessionManagerRunShell"
  document_type = "Session"
  tags          = local.common_tags

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Session Manager preferences for ${local.name_prefix}"
    sessionType   = "Standard_Stream"
    inputs = merge(
      {
        s3BucketName                = coalesce(var.session_manager_s3_bucket, "")
        s3KeyPrefix                 = var.session_manager_s3_prefix
        s3EncryptionEnabled         = true
        cloudWatchLogGroupName      = coalesce(var.session_manager_cloudwatch_log_group, "")
        cloudWatchEncryptionEnabled = var.kms_key_arn != null
        cloudWatchStreamingEnabled  = true
        idleSessionTimeout          = "20"
        maxSessionDuration          = "60"
        shellProfile = {
          linux   = "exec /bin/bash"
          windows = ""
        }
      },
      var.kms_key_arn != null ? { kmsKeyId = var.kms_key_arn } : {}
    )
  })
}

resource "aws_iam_policy" "session_manager" {
  count       = var.enable_session_manager ? 1 : 0
  name        = "${local.name_prefix}-session-manager-policy"
  description = "Allows EC2 instances to use SSM Session Manager — attach to EC2 instance roles"
  tags        = local.common_tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMCore"
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssm:ListInstanceAssociations",
          "ssm:DescribeInstanceProperties",
          "ssm:DescribeDocumentParameters",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = ["logs:DescribeLogGroups", "logs:DescribeLogStreams",
                  "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      },
      {
        Sid      = "S3SessionLogs"
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetEncryptionConfiguration"]
        Resource = var.session_manager_s3_bucket != null ? [
          "arn:aws:s3:::${var.session_manager_s3_bucket}/*"
        ] : ["*"]
      }
    ]
  })
}

##############################################################################
# FEATURE 5: SSM DOCUMENTS
##############################################################################
resource "aws_ssm_document" "custom" {
  for_each = var.documents

  name            = "${local.name_prefix}-${each.key}"
  document_type   = each.value.document_type
  document_format = each.value.document_format
  content         = each.value.content
  target_type     = each.value.target_type
  tags            = local.common_tags
}

##############################################################################
# FEATURE 6: APPCONFIG
##############################################################################
resource "aws_appconfig_application" "this" {
  count       = var.enable_appconfig ? 1 : 0
  name        = coalesce(var.appconfig_application_name, local.name_prefix)
  description = var.appconfig_description
  tags        = local.common_tags
}

resource "aws_appconfig_environment" "this" {
  for_each = var.enable_appconfig ? var.appconfig_environments : {}

  application_id = aws_appconfig_application.this[0].id
  name           = each.key
  description    = each.value.description
  tags           = local.common_tags

  dynamic "monitor" {
    for_each = each.value.monitors
    content {
      alarm_arn      = monitor.value.alarm_arn
      alarm_role_arn = monitor.value.alarm_role_arn
    }
  }
}

resource "aws_appconfig_configuration_profile" "this" {
  for_each = var.enable_appconfig ? var.appconfig_configuration_profiles : {}

  application_id     = aws_appconfig_application.this[0].id
  name               = each.key
  description        = each.value.description
  location_uri       = each.value.location_uri
  type               = each.value.type
  retrieval_role_arn = each.value.retrieval_role_arn
  tags               = local.common_tags

  dynamic "validator" {
    for_each = each.value.validators
    content {
      type    = validator.value.type
      content = validator.value.content
    }
  }
}

resource "aws_appconfig_deployment_strategy" "this" {
  count = var.enable_appconfig ? 1 : 0

  name                           = "${local.name_prefix}-${var.appconfig_deployment_strategy.name}"
  description                    = var.appconfig_deployment_strategy.description
  deployment_duration_in_minutes = var.appconfig_deployment_strategy.deployment_duration_in_minutes
  growth_factor                  = var.appconfig_deployment_strategy.growth_factor
  final_bake_time_in_minutes     = var.appconfig_deployment_strategy.final_bake_time_in_minutes
  growth_type                    = var.appconfig_deployment_strategy.growth_type
  replicate_to                   = var.appconfig_deployment_strategy.replicate_to
  tags                           = local.common_tags
}

##############################################################################
# FEATURE 7: STATE MANAGER ASSOCIATIONS
##############################################################################
resource "aws_ssm_association" "this" {
  for_each = var.associations

  name                        = each.value.document_name
  association_name            = "${local.name_prefix}-${each.key}"
  document_version            = each.value.document_version
  schedule_expression         = each.value.schedule
  compliance_severity         = each.value.compliance_severity
  max_concurrency             = each.value.max_concurrency
  max_errors                  = each.value.max_errors
  apply_only_at_cron_interval = each.value.apply_only_at_cron_interval

  dynamic "targets" {
    for_each = each.value.targets
    content {
      key    = targets.value.key
      values = targets.value.values
    }
  }

  dynamic "output_location" {
    for_each = each.value.output_location != null ? [each.value.output_location] : []
    content {
      s3_bucket_name = output_location.value.s3_bucket_name
      s3_key_prefix  = output_location.value.s3_key_prefix
      s3_region      = output_location.value.s3_region
    }
  }
}

##############################################################################
# FEATURE 8: RESOURCE DATA SYNC
##############################################################################
resource "aws_ssm_resource_data_sync" "this" {
  for_each = var.resource_data_syncs

  name = "${local.name_prefix}-${each.key}"

  s3_destination {
    bucket_name = each.value.s3_bucket_name
    region      = each.value.s3_region
    prefix      = each.value.s3_prefix
    sync_format = each.value.sync_format
    kms_key_arn = each.value.kms_key_arn
  }
}

##############################################################################
# FEATURE 9: HYBRID ACTIVATIONS
##############################################################################
resource "aws_iam_role" "activation" {
  count = var.create_activation ? 1 : 0
  name  = coalesce(var.activation_iam_role_name, "${local.name_prefix}-ssm-activation-role")
  tags  = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ssm.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "activation" {
  count      = var.create_activation ? 1 : 0
  role       = aws_iam_role.activation[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_ssm_activation" "this" {
  count              = var.create_activation ? 1 : 0
  name               = "${local.name_prefix}-hybrid-activation"
  description        = var.activation_description
  iam_role           = aws_iam_role.activation[0].id
  registration_limit = var.activation_registration_limit
  expiration_date    = var.activation_expiration_date
  tags               = local.common_tags

  depends_on = [aws_iam_role_policy_attachment.activation]
}
