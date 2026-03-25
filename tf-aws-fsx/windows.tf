# ===========================================================================
# FSx for WINDOWS FILE SERVER
# ===========================================================================
resource "aws_fsx_windows_file_system" "this" {
  count = var.windows != null ? 1 : 0

  storage_capacity                  = var.windows.storage_capacity
  subnet_ids                        = var.windows.subnet_ids
  security_group_ids                = var.windows.security_group_ids
  deployment_type                   = var.windows.deployment_type
  preferred_subnet_id               = var.windows.deployment_type == "MULTI_AZ_1" ? var.windows.preferred_subnet_id : null
  storage_type                      = var.windows.storage_type
  throughput_capacity               = var.windows.throughput_capacity
  automatic_backup_retention_days   = var.windows.automatic_backup_retention_days
  daily_automatic_backup_start_time = var.windows.daily_automatic_backup_start_time
  weekly_maintenance_start_time     = var.windows.weekly_maintenance_start_time
  copy_tags_to_backups              = var.windows.copy_tags_to_backups
  skip_final_backup                 = var.windows.skip_final_backup
  kms_key_id                        = var.kms_key_arn
  aliases                           = var.windows.aliases

  # AWS Managed AD (preferred)
  active_directory_id = var.windows.active_directory_id

  # Self-managed AD (when AWS Managed AD not used)
  dynamic "self_managed_active_directory" {
    for_each = var.windows.active_directory_id == null && var.windows.self_managed_ad != null ? [var.windows.self_managed_ad] : []
    content {
      domain_name                            = self_managed_active_directory.value.domain_name
      username                               = self_managed_active_directory.value.username
      password                               = self_managed_active_directory.value.password
      dns_ips                                = self_managed_active_directory.value.dns_ips
      organizational_unit_distinguished_name = self_managed_active_directory.value.organizational_unit
      file_system_administrators_group       = self_managed_active_directory.value.file_system_admin_group
    }
  }

  dynamic "audit_log_configuration" {
    for_each = var.windows.audit_log_destination != null ? [1] : []
    content {
      audit_log_destination             = var.windows.audit_log_destination
      file_access_audit_log_level       = var.windows.file_access_audit_log_level
      file_share_access_audit_log_level = var.windows.file_access_audit_log_level
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-windows" })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [weekly_maintenance_start_time, daily_automatic_backup_start_time]
  }
}
