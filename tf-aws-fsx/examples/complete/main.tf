provider "aws" { region = var.aws_region }


module "kms" {
  source      = "../../../tf-aws-kms"
  name_prefix = var.name
  tags = {
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
  }

  keys = {
    fsx = {
      description = "KMS key for ${var.name} FSx resources"
    }
  }
}

module "fsx" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  kms_key_arn = module.kms.key_arns["fsx"]

  windows = var.windows
  lustre  = var.lustre
  ontap   = var.ontap
  openzfs = var.openzfs

  # AWS Backup for ONTAP cross-region (choice-based — set in tfvars)
  enable_ontap_backup                      = var.enable_ontap_backup
  ontap_backup_vault_name                  = var.ontap_backup_vault_name
  ontap_backup_schedule                    = var.ontap_backup_schedule
  ontap_backup_retention_days              = var.ontap_backup_retention_days
  enable_ontap_cross_region_backup         = var.enable_ontap_cross_region_backup
  ontap_cross_region_backup_vault_arn      = var.ontap_cross_region_backup_vault_arn
  ontap_cross_region_backup_kms_key_arn    = var.ontap_cross_region_backup_kms_key_arn
  ontap_cross_region_backup_retention_days = var.ontap_cross_region_backup_retention_days
}
