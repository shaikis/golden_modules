aws_region            = "us-east-1"
environment           = "staging"
project               = "myapp"
source_bucket_name    = "myapp-staging-data"
source_region         = "us-east-1"
kms_name              = "s3-backup"
enable_srr            = true
srr_bucket_name       = "myapp-staging-data-backup"
srr_storage_class     = "STANDARD_IA"
enable_aws_backup     = true
backup_retention_days = 30
source_lifecycle_rules = [
  {
    id = "transition-to-ia"
    transitions = [
      { days = 30; storage_class = "STANDARD_IA" },
      { days = 90; storage_class = "GLACIER" },
    ]
    noncurrent_version_expiration_days = 60
  }
]
tags = { Environment = "staging" }
