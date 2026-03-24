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

# ===========================================================================
# FSx for NetApp ONTAP
# ===========================================================================
resource "aws_fsx_ontap_file_system" "this" {
  count = var.ontap != null ? 1 : 0

  storage_capacity                  = var.ontap.storage_capacity
  subnet_ids                        = var.ontap.subnet_ids
  security_group_ids                = var.ontap.security_group_ids
  deployment_type                   = var.ontap.deployment_type
  preferred_subnet_id               = var.ontap.deployment_type == "MULTI_AZ_1" ? var.ontap.preferred_subnet_id : null
  throughput_capacity               = var.ontap.throughput_capacity
  weekly_maintenance_start_time     = var.ontap.weekly_maintenance_start_time
  automatic_backup_retention_days   = var.ontap.automatic_backup_retention_days
  daily_automatic_backup_start_time = var.ontap.daily_automatic_backup_start_time
  fsx_admin_password                = var.ontap.fsx_admin_password
  route_table_ids                   = var.ontap.route_table_ids
  ha_pairs                          = var.ontap.ha_pairs
  kms_key_id                        = var.kms_key_arn

  tags = merge(local.tags, { Name = "${local.name}-ontap" })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [fsx_admin_password, weekly_maintenance_start_time]
  }
}

# ONTAP Storage Virtual Machines (SVMs)
resource "aws_fsx_ontap_storage_virtual_machine" "this" {
  for_each = var.ontap != null ? var.ontap.svms : {}

  file_system_id             = aws_fsx_ontap_file_system.this[0].id
  name                       = each.value.name
  root_volume_security_style = each.value.root_volume_security_style
  svm_admin_password         = each.value.svm_admin_password

  dynamic "active_directory_configuration" {
    for_each = each.value.active_directory != null ? [each.value.active_directory] : []
    content {
      netbios_name = active_directory_configuration.value.netbios_name
      self_managed_active_directory_configuration {
        dns_ips                                = active_directory_configuration.value.dns_ips
        domain_name                            = active_directory_configuration.value.domain_name
        password                               = active_directory_configuration.value.password
        username                               = active_directory_configuration.value.username
        file_system_administrators_group       = active_directory_configuration.value.file_system_admin_group
        organizational_unit_distinguished_name = active_directory_configuration.value.organizational_unit_distinguished_name
      }
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-svm-${each.key}" })

  lifecycle {
    ignore_changes = [svm_admin_password]
  }
}

# ONTAP Volumes (within SVMs)
resource "aws_fsx_ontap_volume" "this" {
  for_each = {
    for item in flatten([
      for svm_key, svm_val in(var.ontap != null ? var.ontap.svms : {}) : [
        for vol_key, vol_val in svm_val.volumes : {
          key     = "${svm_key}-${vol_key}"
          svm_key = svm_key
          vol     = vol_val
        }
      ]
    ]) : item.key => item
  }

  storage_virtual_machine_id           = aws_fsx_ontap_storage_virtual_machine.this[each.value.svm_key].id
  name                                 = each.value.vol.name
  junction_path                        = each.value.vol.junction_path
  size_in_megabytes                    = each.value.vol.size_in_megabytes
  security_style                       = each.value.vol.security_style
  storage_efficiency_enabled           = each.value.vol.storage_efficiency
  snapshot_policy                      = each.value.vol.snapshot_policy
  copy_tags_to_backups                 = each.value.vol.copy_tags_to_backups
  bypass_snaplock_enterprise_retention = each.value.vol.bypass_snaplock_enterprise_retention

  dynamic "tiering_policy" {
    for_each = each.value.vol.tiering_policy != null ? [each.value.vol.tiering_policy] : []
    content {
      name           = tiering_policy.value.name
      cooling_period = tiering_policy.value.cooling_period
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-vol-${each.key}" })

  lifecycle {
    prevent_destroy = true
  }
}

# ===========================================================================
# FSx for OpenZFS
# ===========================================================================
resource "aws_fsx_openzfs_file_system" "this" {
  count = var.openzfs != null ? 1 : 0

  storage_capacity                  = var.openzfs.storage_capacity
  subnet_ids                        = var.openzfs.subnet_ids
  security_group_ids                = var.openzfs.security_group_ids
  deployment_type                   = var.openzfs.deployment_type
  throughput_capacity               = var.openzfs.throughput_capacity
  storage_type                      = var.openzfs.storage_type
  automatic_backup_retention_days   = var.openzfs.automatic_backup_retention_days
  daily_automatic_backup_start_time = var.openzfs.daily_automatic_backup_start_time
  copy_tags_to_backups              = var.openzfs.copy_tags_to_backups
  skip_final_backup                 = var.openzfs.skip_final_backup
  weekly_maintenance_start_time     = var.openzfs.weekly_maintenance_start_time
  kms_key_id                        = var.kms_key_arn

  root_volume_configuration {
    copy_tags_to_snapshots = var.openzfs.root_volume_copy_tags_to_snapshots
    data_compression_type  = var.openzfs.root_volume_data_compression_type
    read_only              = var.openzfs.root_volume_read_only
    record_size_kib        = var.openzfs.root_volume_record_size_kib
  }

  tags = merge(local.tags, { Name = "${local.name}-openzfs" })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [weekly_maintenance_start_time]
  }
}

# OpenZFS child volumes
resource "aws_fsx_openzfs_volume" "this" {
  for_each = var.openzfs != null ? var.openzfs.volumes : {}

  parent_volume_id = coalesce(
    each.value.parent_volume_id,
    aws_fsx_openzfs_file_system.this[0].root_volume_id
  )
  name = each.value.name
  # Defaults to "/<volume-name>" when not explicitly provided (junction_path is required by AWS)
  junction_path                    = coalesce(each.value.junction_path, "/${each.value.name}")
  storage_capacity_quota_gib       = each.value.storage_capacity_quota_gib
  storage_capacity_reservation_gib = each.value.storage_capacity_reservation_gib
  data_compression_type            = each.value.data_compression_type
  read_only                        = each.value.read_only
  record_size_kib                  = each.value.record_size_kib
  copy_tags_to_snapshots           = each.value.copy_tags_to_snapshots

  dynamic "nfs_exports" {
    for_each = each.value.nfs_exports
    content {
      dynamic "client_configurations" {
        for_each = nfs_exports.value.client_configurations
        content {
          clients = client_configurations.value.clients
          options = client_configurations.value.options
        }
      }
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-zfs-${each.key}" })

  lifecycle {
    prevent_destroy = true
  }
}

# ===========================================================================
# AWS Backup for FSx ONTAP — Cross-Region Replication (choice-based)
# Set enable_ontap_backup = true  to enable local backups
# Set enable_ontap_cross_region_backup = true  to also copy to a DR region
# ===========================================================================

# ---------------------------------------------------------------------------
# IAM Role for AWS Backup Service
# ---------------------------------------------------------------------------
resource "aws_iam_role" "ontap_backup" {
  count = var.ontap != null && var.enable_ontap_backup ? 1 : 0

  name = "${local.name}-fsx-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores",
  ]

  tags = local.tags
}

# ---------------------------------------------------------------------------
# AWS Backup Vault — primary region
# ---------------------------------------------------------------------------
resource "aws_backup_vault" "ontap" {
  count = var.ontap != null && var.enable_ontap_backup ? 1 : 0

  name        = coalesce(var.ontap_backup_vault_name, "${local.name}-fsx-vault")
  kms_key_arn = var.kms_key_arn

  tags = local.tags
}

# ---------------------------------------------------------------------------
# AWS Backup Plan — schedule + optional cross-region copy rule
# ---------------------------------------------------------------------------
resource "aws_backup_plan" "ontap" {
  count = var.ontap != null && var.enable_ontap_backup ? 1 : 0

  name = "${local.name}-fsx-ontap-plan"

  rule {
    rule_name         = "daily-fsx-backup"
    target_vault_name = aws_backup_vault.ontap[0].name
    schedule          = var.ontap_backup_schedule

    lifecycle {
      delete_after = var.ontap_backup_retention_days
    }

    # Cross-region copy — only when enabled and destination vault ARN is provided
    dynamic "copy_action" {
      for_each = (
        var.enable_ontap_cross_region_backup &&
        var.ontap_cross_region_backup_vault_arn != null
        ? [1] : []
      )
      content {
        destination_vault_arn = var.ontap_cross_region_backup_vault_arn
        lifecycle {
          delete_after = var.ontap_cross_region_backup_retention_days
        }
      }
    }
  }

  tags = local.tags
}

# ---------------------------------------------------------------------------
# AWS Backup Selection — attach the FSx ONTAP file system to the plan
# ---------------------------------------------------------------------------
resource "aws_backup_selection" "ontap" {
  count = var.ontap != null && var.enable_ontap_backup ? 1 : 0

  name         = "${local.name}-fsx-ontap-selection"
  plan_id      = aws_backup_plan.ontap[0].id
  iam_role_arn = aws_iam_role.ontap_backup[0].arn

  resources = [
    aws_fsx_ontap_file_system.this[0].arn
  ]
}
