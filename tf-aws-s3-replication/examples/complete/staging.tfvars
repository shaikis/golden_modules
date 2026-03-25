primary_region       = "us-east-1"
dr_west_region       = "us-west-2"
dr_eu_region         = "eu-west-1"
environment          = "staging"
project              = "platform"
owner                = "data-team"
cost_center          = "CC-200"
source_bucket_name   = "platform-staging-data"
source_region        = "us-east-1"
dr_west_bucket_name  = "platform-staging-data-dr-us-west-2"
dr_eu_bucket_name    = "platform-staging-data-dr-eu-west-1"
enable_srr           = true
srr_bucket_name      = "platform-staging-data-srr-backup"
srr_storage_class    = "STANDARD_IA"
enable_crr           = true
enable_aws_backup    = true
backup_vault_name    = "platform-staging-vault"
backup_schedule      = "cron(0 2 * * ? *)"
backup_retention_days = 30
source_lifecycle_rules = [
  {
    id = "standard-lifecycle"
    transitions = [
      { days = 30;  storage_class = "STANDARD_IA" },
      { days = 90;  storage_class = "GLACIER" },
    ]
    noncurrent_version_expiration_days = 60
  }
]
tags = { Environment = "staging", DataClassification = "Confidential" }
