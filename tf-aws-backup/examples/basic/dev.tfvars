aws_region  = "us-east-1"
name        = "myapp"
environment = "dev"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"
tags        = {}

create_iam_role  = true
iam_role_arn     = null
enable_s3_backup = false

vault_kms_key_arn   = null
vault_force_destroy = true
vault_sns_topic_arn = null

daily_retention_days   = 7
cross_region_vault_arn = null

backup_tag_key   = "Backup"
backup_tag_value = "true"

enable_cloudwatch_logs      = false
log_retention_days          = 30
log_kms_key_arn             = null
create_cloudwatch_alarms    = false
alarm_actions               = []
backup_job_failed_threshold = 1
copy_job_failed_threshold   = 1
create_cloudwatch_dashboard = false
dashboard_name              = null
