provider "aws" {
  region = var.primary_region
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

module "backup" {
  source = "../../modules/aws-backup"

  ##########################################
  # Naming
  ##########################################
  name        = var.name
  name_prefix = var.name_prefix
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  ##########################################
  # IAM
  ##########################################
  create_iam_role = true
  iam_role_name   = var.iam_role_name

  ##########################################
  # SNS
  ##########################################
  create_sns_topic = var.create_sns_topic
  sns_topic_arn    = var.sns_topic_arn
  sns_kms_key_id   = var.sns_kms_key_id

  ##########################################
  # Vaults
  ##########################################
  vaults = {
    primary = {
      enable_vault_lock             = true
      vault_lock_min_retention_days = 7
      vault_lock_max_retention_days = 3650

      tags = {
        Vault = "primary"
      }
    }
  }

  ##########################################
  # Backup Plans
  ##########################################
  plans = {
    ebs_plan = {
      rules = [
        {
          rule_name = "daily"

          vault_key = "primary"

          schedule = "cron(0 5 * * ? *)"

          lifecycle = {
            delete_after = 35
          }

          copy_actions = [
            {
              destination_vault_arn = var.dr_vault_arn

              lifecycle = {
                delete_after = 60
              }
            }
          ]
        },
        {
          rule_name = "monthly"

          vault_key = "primary"

          schedule = "cron(0 7 1 * ? *)"

          lifecycle = {
            cold_storage_after = 30
            delete_after       = 365
          }

          copy_actions = [
            {
              destination_vault_arn = var.dr_vault_arn

              lifecycle = {
                cold_storage_after = 60
                delete_after       = 730
              }
            }
          ]
        }
      ]

      advanced_backup_settings = [
        {
          resource_type = "EC2"
          backup_options = {
            WindowsVSS = "enabled"
          }
        }
      ]
    }
  }

  ##########################################
  # Selections
  ##########################################
  selections = {
    ebs = {
      plan_key = "ebs_plan"

      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Backup"
          value = "true"
        }
      ]
    }
  }

  ##########################################
  # Audit Framework
  ##########################################
  create_framework = true

  framework_controls = [
    {
      name = "BACKUP_RECOVERY_POINT_ENCRYPTED"
    },
    {
      name = "BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK"
      input_parameters = [
        {
          name  = "requiredRetentionDays"
          value = "30"
        }
      ]
    }
  ]

  ##########################################
  # Reports
  ##########################################
  report_plans = {
    backup_report = {
      report_template = "BACKUP_JOB_REPORT"
      s3_bucket_name  = var.report_bucket

      formats = ["CSV", "JSON"]
    }
  }

  ##########################################
  # CloudWatch Logs, Alarms & Dashboard
  ##########################################
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