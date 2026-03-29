provider "aws" { region = var.aws_region }

locals {
  restore_testing_plans = var.enable_restore_testing ? {
    weekly = {
      algorithm                    = "LATEST_WITHIN_WINDOW"
      recovery_point_types         = ["SNAPSHOT"]
      include_vaults               = var.backup_vault_arns
      exclude_vaults               = []
      selection_window_days        = 7
      schedule_expression          = "cron(0 6 ? * SUN *)"
      schedule_expression_timezone = "UTC"
      start_window_hours           = 2
      tags                         = {}
    }
  } : {}

  restore_testing_selections = var.enable_restore_testing ? {
    ec2_test = {
      restore_testing_plan_key = "weekly"
      protected_resource_type  = "EC2"
      protected_resource_arns  = []
      protected_resource_conditions = {
        string_equals = [{
          key   = "aws:ResourceTag/RestoreTest"
          value = "true"
        }]
        string_not_equals = []
      }
      restore_metadata_overrides = {
        instanceType     = var.restore_test_instance_type
        availabilityZone = var.restore_test_az
      }
      validation_window_hours = 4
      iam_role_arn            = null
    }
  } : {}
}

module "restore" {
  source      = "../../"
  name        = var.name
  name_prefix = var.name_prefix
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  create_iam_role    = var.create_iam_role
  iam_role_arn       = var.iam_role_arn
  enable_s3_restore  = var.enable_s3_restore
  enable_ec2_restore = var.enable_ec2_restore
  enable_rds_restore = var.enable_rds_restore
  enable_dynamodb_restore = var.enable_dynamodb_restore
  enable_ebs_restore      = var.enable_ebs_restore
  enable_efs_restore = var.enable_efs_restore
  enable_fsx_restore = var.enable_fsx_restore
  enable_redshift_restore = var.enable_redshift_restore

  rds_resource_arns      = var.rds_resource_arns
  dynamodb_resource_arns = var.dynamodb_resource_arns
  ebs_resource_arns      = var.ebs_resource_arns
  efs_resource_arns      = var.efs_resource_arns
  fsx_resource_arns      = var.fsx_resource_arns
  redshift_resource_arns = var.redshift_resource_arns
  kms_key_arns           = var.kms_key_arns
  pass_role_arns         = var.pass_role_arns

  create_sns_topic = var.create_sns_topic
  sns_topic_arn    = var.sns_topic_arn
  sns_kms_key_id   = var.sns_kms_key_id

  create_cloudwatch_alarms       = var.create_cloudwatch_alarms
  alarm_actions                  = var.alarm_actions
  restore_job_failed_threshold   = var.restore_job_failed_threshold
  restore_job_evaluation_periods = var.restore_job_evaluation_periods
  restore_job_period             = var.restore_job_period

  restore_testing_plans      = local.restore_testing_plans
  restore_testing_selections = local.restore_testing_selections

  enable_cloudwatch_logs      = var.enable_cloudwatch_logs
  log_retention_days          = var.log_retention_days
  log_kms_key_arn             = var.log_kms_key_arn
  create_cloudwatch_dashboard = var.create_cloudwatch_dashboard
  dashboard_name              = var.dashboard_name
}
