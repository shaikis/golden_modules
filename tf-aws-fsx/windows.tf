# ===========================================================================
# FSx for WINDOWS FILE SERVER
# ===========================================================================
resource "aws_fsx_windows_file_system" "this" {
  count = local.resolved_windows != null ? 1 : 0

  storage_capacity                  = local.resolved_windows.storage_capacity
  subnet_ids                        = local.resolved_windows.subnet_ids
  security_group_ids                = local.resolved_windows.security_group_ids
  deployment_type                   = local.resolved_windows.deployment_type
  preferred_subnet_id               = local.resolved_windows.deployment_type == "MULTI_AZ_1" ? local.resolved_windows.preferred_subnet_id : null
  storage_type                      = local.resolved_windows.storage_type
  throughput_capacity               = local.resolved_windows.throughput_capacity
  automatic_backup_retention_days   = local.resolved_windows.automatic_backup_retention_days
  daily_automatic_backup_start_time = local.resolved_windows.daily_automatic_backup_start_time
  weekly_maintenance_start_time     = local.resolved_windows.weekly_maintenance_start_time
  copy_tags_to_backups              = local.resolved_windows.copy_tags_to_backups
  skip_final_backup                 = local.resolved_windows.skip_final_backup
  kms_key_id                        = var.kms_key_arn
  aliases                           = local.resolved_windows.aliases

  # AWS Managed AD (preferred)
  active_directory_id = local.resolved_windows.active_directory_id

  # Self-managed AD (when AWS Managed AD not used)
  dynamic "self_managed_active_directory" {
    for_each = local.resolved_windows.active_directory_id == null && local.resolved_windows.self_managed_ad != null ? [local.resolved_windows.self_managed_ad] : []
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
    for_each = local.resolved_windows.audit_log_destination != null ? [1] : []
    content {
      audit_log_destination             = local.resolved_windows.audit_log_destination
      file_access_audit_log_level       = local.resolved_windows.file_access_audit_log_level
      file_share_access_audit_log_level = local.resolved_windows.file_access_audit_log_level
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-windows" })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [weekly_maintenance_start_time, daily_automatic_backup_start_time]
  }
}
