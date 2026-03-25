provider "aws" { region = var.aws_region }

locals {
  vaults = {
    primary = {
      kms_key_arn                    = var.vault_kms_key_arn
      force_destroy                  = var.vault_force_destroy
      policy                         = null
      enable_vault_lock              = false
      vault_lock_changeable_for_days = null
      vault_lock_max_retention_days  = null
      vault_lock_min_retention_days  = null
      sns_topic_arn                  = var.vault_sns_topic_arn
      notification_events = [
        "BACKUP_JOB_STARTED", "BACKUP_JOB_COMPLETED", "BACKUP_JOB_FAILED",
        "RESTORE_JOB_STARTED", "RESTORE_JOB_COMPLETED",
      ]
      tags = {}
    }
  }

  cross_region_copy = var.cross_region_vault_arn != null ? [{
    destination_vault_arn = var.cross_region_vault_arn
    lifecycle = {
      cold_storage_after = null
      delete_after       = var.daily_retention_days
    }
  }] : []

  plans = {
    daily = {
      rules = [{
        rule_name                    = "daily-backup"
        vault_key                    = "primary"
        target_vault_name            = null
        schedule                     = "cron(0 5 * * ? *)"
        schedule_expression_timezone = "UTC"
        start_window                 = 60
        completion_window            = 180
        enable_continuous_backup     = false
        recovery_point_tags          = { BackupType = "daily" }
        lifecycle = {
          cold_storage_after                        = null
          delete_after                              = var.daily_retention_days
          opt_in_to_archive_for_supported_resources = false
        }
        copy_actions = local.cross_region_copy
      }]
      advanced_backup_settings = []
      tags                     = {}
    }
  }

  selections = {
    tagged_resources = {
      plan_key      = "daily"
      iam_role_arn  = null
      resources     = []
      not_resources = []
      selection_tags = [{
        type  = "STRINGEQUALS"
        key   = var.backup_tag_key
        value = var.backup_tag_value
      }]
      conditions = null
    }
  }
}

module "backup" {
  source      = "../../"
  name        = var.name
  name_prefix = var.name_prefix
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  create_iam_role  = var.create_iam_role
  iam_role_arn     = var.iam_role_arn
  enable_s3_backup = var.enable_s3_backup

  create_sns_topic = var.create_sns_topic
  sns_topic_arn    = var.sns_topic_arn
  sns_kms_key_id   = var.sns_kms_key_id

  vaults     = local.vaults
  plans      = local.plans
  selections = local.selections

  create_framework                    = false
  framework_description               = ""
  framework_controls                  = []
  report_plans                        = {}
  configure_global_settings           = false
  enable_cross_account_backup         = false
  configure_region_settings           = false
  resource_type_opt_in_preference     = {}
  resource_type_management_preference = {}

  enable_cloudwatch_logs      = var.enable_cloudwatch_logs
  log_retention_days          = var.log_retention_days
  log_kms_key_arn             = var.log_kms_key_arn
  create_cloudwatch_alarms    = var.create_cloudwatch_alarms
  alarm_actions               = var.alarm_actions
  backup_job_failed_threshold = var.backup_job_failed_threshold
  copy_job_failed_threshold   = var.copy_job_failed_threshold
  create_cloudwatch_dashboard = var.create_cloudwatch_dashboard
  dashboard_name              = var.dashboard_name
}
