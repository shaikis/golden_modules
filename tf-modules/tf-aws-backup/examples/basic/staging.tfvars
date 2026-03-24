aws_region  = "us-east-1"
name        = "myapp"
environment = "staging"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"
tags        = {}

create_iam_role  = true
iam_role_arn     = null
enable_s3_backup = false

vault_kms_key_arn   = null
vault_force_destroy = false
vault_sns_topic_arn = null

daily_retention_days   = 14
cross_region_vault_arn = null

backup_tag_key   = "Backup"
backup_tag_value = "true"
