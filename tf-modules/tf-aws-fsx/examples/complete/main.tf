provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name        = "${var.name}-fsx"
  environment = var.environment
}

module "fsx" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  kms_key_arn = module.kms.key_arn

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

output "windows_dns_name" { value = module.fsx.windows_fs_dns_name }
output "lustre_dns_name" { value = module.fsx.lustre_fs_dns_name }
output "ontap_svm_ids" { value = module.fsx.ontap_svm_ids }
output "ontap_volume_junctions" { value = module.fsx.ontap_volume_junction_paths }
output "openzfs_dns_name" { value = module.fsx.openzfs_fs_dns_name }
output "ontap_backup_vault_arn" { value = module.fsx.ontap_backup_vault_arn }
output "ontap_backup_plan_arn" { value = module.fsx.ontap_backup_plan_arn }
