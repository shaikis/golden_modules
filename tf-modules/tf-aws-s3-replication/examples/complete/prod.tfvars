primary_region       = "us-east-1"
dr_west_region       = "us-west-2"
dr_eu_region         = "eu-west-1"
environment          = "prod"
project              = "platform"
owner                = "data-team"
cost_center          = "CC-200"
source_bucket_name   = "platform-prod-data"
source_region        = "us-east-1"
dr_west_bucket_name  = "platform-prod-data-dr-us-west-2"
dr_eu_bucket_name    = "platform-prod-data-dr-eu-west-1"
enable_srr           = true
srr_bucket_name      = "platform-prod-data-srr-backup"
srr_storage_class    = "STANDARD_IA"
enable_crr           = true
enable_aws_backup    = true
backup_vault_name    = "platform-prod-vault"
backup_schedule      = "cron(0 1 * * ? *)"
backup_retention_days = 90
source_lifecycle_rules = [
  {
    id = "standard-lifecycle"
    transitions = [
      { days = 30;  storage_class = "STANDARD_IA" },
      { days = 90;  storage_class = "GLACIER" },
      { days = 365; storage_class = "DEEP_ARCHIVE" },
    ]
    noncurrent_version_expiration_days = 90
  }
]
tags = { Environment = "prod", DataClassification = "Confidential", Compliance = "SOC2" }
