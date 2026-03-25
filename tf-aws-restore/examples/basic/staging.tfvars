aws_region  = "us-east-1"
name        = "myapp"
environment = "staging"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"
tags        = {}

create_iam_role    = true
iam_role_arn       = null
enable_s3_restore  = false
enable_ec2_restore = true
enable_rds_restore = true
enable_efs_restore = false
enable_fsx_restore = false

create_sns_topic = false
sns_topic_arn    = null
sns_kms_key_id   = null

create_cloudwatch_alarms       = true
alarm_actions                  = []
restore_job_failed_threshold   = 1
restore_job_evaluation_periods = 1
restore_job_period             = 86400

enable_restore_testing     = true
backup_vault_arns          = ["*"]
restore_test_instance_type = "t3.micro"
restore_test_az            = "us-east-1a"
