primary_region = "eu-west-3"
dr_region      = "eu-central-1"

name        = "backup"
name_prefix = "platform"
environment = "prod"
project     = "core"
owner       = "infra"
cost_center = "shared"

tags = {
  Compliance = "SOC2"
  ManagedBy  = "Terraform"
}

iam_role_name = "prod-backup-role"

dr_vault_arn  = "arn:aws:backup:eu-central-1:123456789012:backup-vault:dr-vault"
report_bucket = "prod-backup-reports"