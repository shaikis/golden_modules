aws_region  = "us-east-1"
name        = "myapp"
environment = "prod"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"
tags        = { Compliance = "SOC2" }

create_iam_role  = true
iam_role_arn     = null
enable_s3_backup = true

vault_kms_key_arn   = "arn:aws:kms:us-east-1:123456789012:key/mrk-xxxxxxxxxxxxxxxx"
vault_force_destroy = false
vault_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:backup-alerts"

daily_retention_days   = 35
cross_region_vault_arn = "arn:aws:backup:us-west-2:123456789012:backup-vault:myapp-prod-primary"

backup_tag_key   = "Backup"
backup_tag_value = "true"

enable_cloudwatch_logs      = true
log_retention_days          = 365
log_kms_key_arn             = null
create_cloudwatch_alarms    = true
alarm_actions               = []
backup_job_failed_threshold = 1
copy_job_failed_threshold   = 1
create_cloudwatch_dashboard = true
dashboard_name              = null
