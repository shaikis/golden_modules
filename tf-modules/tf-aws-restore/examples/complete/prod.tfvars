aws_region  = "us-east-1"
name        = "myapp"
environment = "prod"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"
tags        = { Compliance = "SOC2" }

# IAM Role — choose ONE approach:
# Option A (default): Let module create a new role
create_iam_role = true
iam_role_arn    = null
# Option B (BYO): Pass existing role from another module
# create_iam_role = false
# iam_role_arn    = "arn:aws:iam::123456789012:role/existing-backup-role"

enable_s3_restore  = true
enable_ec2_restore = true
enable_rds_restore = true
enable_efs_restore = true
enable_fsx_restore = false

# SNS Topic — choose ONE approach:
# Option A: Let module create a new topic
create_sns_topic = true
sns_topic_arn    = null
# Option B (BYO): Pass existing topic ARN from SNS module output
# create_sns_topic = false
# sns_topic_arn    = "arn:aws:sns:us-east-1:123456789012:existing-backup-topic"
# Option C: No notifications
# create_sns_topic = false
# sns_topic_arn    = null

sns_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/mrk-xxxxxxxxxxxxxxxx"

create_cloudwatch_alarms       = true
alarm_actions                  = ["arn:aws:sns:us-east-1:123456789012:pagerduty-alerts"]
restore_job_failed_threshold   = 1
restore_job_evaluation_periods = 1
restore_job_period             = 86400

backup_timezone = "America/New_York"
backup_vault_arns = [
  "arn:aws:backup:us-east-1:123456789012:backup-vault:myapp-prod-primary",
  "arn:aws:backup:us-east-1:123456789012:backup-vault:myapp-prod-longterm",
]

restore_az                 = "us-east-1a"
restore_subnet_id          = "subnet-xxxxxxxxxxxxxxxxx"
restore_ec2_instance_type  = "t3.medium"
restore_rds_instance_class = "db.t3.medium"

rds_resource_arns = [
  "arn:aws:rds:us-east-1:123456789012:db:prod-mysql-01",
  "arn:aws:rds:us-east-1:123456789012:db:prod-postgres-01",
]
efs_resource_arns = [
  "arn:aws:elasticfilesystem:us-east-1:123456789012:file-system/fs-xxxxxxxxx",
]
dynamodb_resource_arns = [
  "arn:aws:dynamodb:us-east-1:123456789012:table/prod-users",
]

enable_cloudwatch_logs      = true
log_retention_days          = 365
log_kms_key_arn             = null
create_cloudwatch_dashboard = true
dashboard_name              = null
