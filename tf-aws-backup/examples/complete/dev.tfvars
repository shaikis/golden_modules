aws_region  = "us-east-1"
name        = "myapp"
name_prefix = ""
environment = "dev"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"

tags = {
  Team        = "infra"
  Environment = "dev"
}

create_iam_role  = true
iam_role_arn     = null
enable_s3_backup = false

# Vaults
primary_vault_kms_key_arn      = null
longterm_vault_kms_key_arn     = null
vault_force_destroy            = true
enable_vault_lock              = false
vault_lock_changeable_for_days = null
vault_lock_max_retention_days  = null
vault_lock_min_retention_days  = null
sns_topic_arn                  = null

# Schedules
backup_timezone    = "UTC"
enable_windows_vss = false

# Retention (shorter for dev)
daily_retention_days      = 7
pitr_retention_days       = 7
weekly_retention_days     = 14
monthly_3m_retention_days = 30
monthly_6m_retention_days = 60
monthly_2y_retention_days = 90

# Cross-region
dr_vault_arn = null

# Monthly backup targets
monthly_backup_resource_arns = []

# Framework & Reporting
create_framework  = false
reports_s3_bucket = null

# Account-level settings
configure_global_settings           = false
enable_cross_account_backup         = false
configure_region_settings           = false
resource_type_opt_in_preference     = {}
resource_type_management_preference = {}

enable_cloudwatch_logs      = false
log_retention_days          = 30
log_kms_key_arn             = null
create_cloudwatch_alarms    = false
alarm_actions               = []
backup_job_failed_threshold = 1
copy_job_failed_threshold   = 1
create_cloudwatch_dashboard = false
dashboard_name              = null
