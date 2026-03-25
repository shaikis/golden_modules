primary_region       = "us-east-1"
dr_west_region       = "us-west-2"
dr_eu_region         = "eu-west-1"
environment          = "dev"
project              = "platform"
owner                = "data-team"
cost_center          = "CC-200"
source_bucket_name   = "platform-dev-data"
source_region        = "us-east-1"
dr_west_bucket_name  = "platform-dev-data-dr-us-west-2"
dr_eu_bucket_name    = "platform-dev-data-dr-eu-west-1"
enable_srr           = true
srr_bucket_name      = "platform-dev-data-srr-backup"
srr_storage_class    = "STANDARD"
enable_crr           = false
enable_aws_backup    = false
backup_vault_name    = "platform-dev-vault"
backup_schedule      = "cron(0 2 * * ? *)"
backup_retention_days = 7
source_lifecycle_rules = [
  {
    id = "standard-lifecycle"
    transitions = [
      { days = 90;  storage_class = "STANDARD_IA" },
    ]
    noncurrent_version_expiration_days = 30
  }
]
tags = { Environment = "dev", DataClassification = "Internal" }
