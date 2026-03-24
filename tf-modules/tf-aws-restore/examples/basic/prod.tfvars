aws_region  = "us-east-1"
name        = "myapp"
environment = "prod"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"
tags        = { Compliance = "SOC2" }

create_iam_role    = true
iam_role_arn       = null
enable_s3_restore  = true
enable_ec2_restore = true
enable_rds_restore = true
enable_efs_restore = true
enable_fsx_restore = false

create_sns_topic = true
sns_topic_arn    = null
sns_kms_key_id   = "arn:aws:kms:us-east-1:123456789012:key/mrk-xxxxxxxxxxxxxxxx"

create_cloudwatch_alarms       = true
alarm_actions                  = ["arn:aws:sns:us-east-1:123456789012:pagerduty-alerts"]
restore_job_failed_threshold   = 1
restore_job_evaluation_periods = 1
restore_job_period             = 86400

enable_restore_testing     = true
backup_vault_arns          = ["arn:aws:backup:us-east-1:123456789012:backup-vault:myapp-prod-primary"]
restore_test_instance_type = "t3.medium"
restore_test_az            = "us-east-1a"

enable_cloudwatch_logs      = true
log_retention_days          = 365
log_kms_key_arn             = null
create_cloudwatch_dashboard = true
dashboard_name              = null
