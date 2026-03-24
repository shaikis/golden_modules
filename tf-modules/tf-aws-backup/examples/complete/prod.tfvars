aws_region  = "us-east-1"
name        = "myapp"
name_prefix = ""
environment = "prod"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"

tags = {
  Team        = "infra"
  Environment = "prod"
  Compliance  = "SOC2"
}

create_iam_role  = true
iam_role_arn     = null
enable_s3_backup = true

# Vaults
primary_vault_kms_key_arn      = "arn:aws:kms:us-east-1:123456789012:key/mrk-xxxxxxxxxxxxxxxx"
longterm_vault_kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/mrk-yyyyyyyyyyyyyyyy"
vault_force_destroy            = false
enable_vault_lock              = true
vault_lock_changeable_for_days = 3
vault_lock_max_retention_days  = 730
vault_lock_min_retention_days  = 7
sns_topic_arn                  = "arn:aws:sns:us-east-1:123456789012:backup-alerts"

# Schedules
backup_timezone    = "America/New_York"
enable_windows_vss = true

# Retention (full production retentions)
daily_retention_days      = 35
pitr_retention_days       = 35
weekly_retention_days     = 35
monthly_3m_retention_days = 90
monthly_6m_retention_days = 180
monthly_2y_retention_days = 730

# Cross-region DR
dr_vault_arn = "arn:aws:backup:us-west-2:123456789012:backup-vault:myapp-prod-dr"

# Monthly backup targets (specific production databases)
monthly_backup_resource_arns = [
  "arn:aws:rds:us-east-1:123456789012:db:prod-mysql-01",
  "arn:aws:rds:us-east-1:123456789012:db:prod-postgres-01",
  "arn:aws:dynamodb:us-east-1:123456789012:table/prod-users",
]

# Framework & Reporting
create_framework  = true
reports_s3_bucket = "myapp-prod-backup-reports"

# Account-level settings
configure_global_settings   = true
enable_cross_account_backup = false
configure_region_settings   = true
resource_type_opt_in_preference = {
  "Aurora"   = true
  "DynamoDB" = true
  "EBS"      = true
  "EC2"      = true
  "EFS"      = true
  "FSx"      = true
  "RDS"      = true
  "S3"       = true
}
resource_type_management_preference = {
  "DynamoDB" = true
  "EFS"      = true
}

enable_cloudwatch_logs      = true
log_retention_days          = 365
log_kms_key_arn             = null
create_cloudwatch_alarms    = true
alarm_actions               = []
backup_job_failed_threshold = 1
copy_job_failed_threshold   = 1
create_cloudwatch_dashboard = true
dashboard_name              = null
