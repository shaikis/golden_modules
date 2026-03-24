aws_region            = "us-east-1"
environment           = "dev"
project               = "myapp"
source_bucket_name    = "myapp-dev-data"
source_region         = "us-east-1"
kms_name              = "s3-backup"
enable_srr            = true
srr_bucket_name       = "myapp-dev-data-backup"
srr_storage_class     = "STANDARD"
enable_aws_backup     = false
backup_retention_days = 14
source_lifecycle_rules = [
  {
    id = "transition-to-ia"
    transitions = [
      { days = 90; storage_class = "STANDARD_IA" },
    ]
    noncurrent_version_expiration_days = 30
  }
]
tags = { Environment = "dev" }
