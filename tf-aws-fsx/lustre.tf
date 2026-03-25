# ===========================================================================
# FSx for LUSTRE
# ===========================================================================
resource "aws_fsx_lustre_file_system" "this" {
  count = var.lustre != null ? 1 : 0

  storage_capacity                = var.lustre.storage_capacity
  subnet_ids                      = var.lustre.subnet_ids
  security_group_ids              = var.lustre.security_group_ids
  deployment_type                 = var.lustre.deployment_type
  storage_type                    = var.lustre.storage_type
  per_unit_storage_throughput     = var.lustre.per_unit_storage_throughput
  data_compression_type           = var.lustre.data_compression_type
  automatic_backup_retention_days = var.lustre.automatic_backup_retention_days
  copy_tags_to_backups            = var.lustre.copy_tags_to_backups
  weekly_maintenance_start_time   = var.lustre.weekly_maintenance_start_time
  file_system_type_version        = var.lustre.file_system_type_version
  import_path                     = var.lustre.import_path
  export_path                     = var.lustre.export_path
  kms_key_id                      = var.kms_key_arn

  tags = merge(local.tags, { Name = "${local.name}-lustre" })

  lifecycle {
    prevent_destroy = true
  }
}
