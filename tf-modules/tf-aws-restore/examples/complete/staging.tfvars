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
enable_efs_restore = true
enable_fsx_restore = false

create_sns_topic = false
sns_topic_arn    = null
sns_kms_key_id   = null

create_cloudwatch_alarms       = true
alarm_actions                  = []
restore_job_failed_threshold   = 1
restore_job_evaluation_periods = 1
restore_job_period             = 86400

backup_timezone   = "UTC"
backup_vault_arns = ["*"]

restore_az                 = "us-east-1a"
restore_subnet_id          = ""
restore_ec2_instance_type  = "t3.micro"
restore_rds_instance_class = "db.t3.micro"

rds_resource_arns      = []
efs_resource_arns      = []
dynamodb_resource_arns = []
