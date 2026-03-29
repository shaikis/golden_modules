# =============================================================================
# DataSync Locations
# =============================================================================

# ── S3 ────────────────────────────────────────────────────────────────────────
resource "aws_datasync_location_s3" "this" {
  for_each = var.s3_locations

  s3_bucket_arn = each.value.s3_bucket_arn
  subdirectory  = each.value.subdirectory

  s3_config {
    bucket_access_role_arn = each.value.s3_config_bucket_access_role_arn
  }

  s3_storage_class = each.value.s3_storage_class
  agent_arns       = each.value.agent_arns

  tags = merge(local.tags, { LocationType = "S3", LocationKey = each.key })
}

# ── EFS ───────────────────────────────────────────────────────────────────────
resource "aws_datasync_location_efs" "this" {
  for_each = var.efs_locations

  efs_file_system_arn = each.value.efs_file_system_arn
  subdirectory        = each.value.subdirectory

  ec2_config {
    subnet_arn          = each.value.ec2_config.subnet_arn
    security_group_arns = each.value.ec2_config.security_group_arns
  }

  in_transit_encryption           = each.value.in_transit_encryption
  access_point_arn                = each.value.access_point_arn
  file_system_access_role_arn     = each.value.file_system_access_role_arn

  tags = merge(local.tags, { LocationType = "EFS", LocationKey = each.key })
}

# ── NFS ───────────────────────────────────────────────────────────────────────
resource "aws_datasync_location_nfs" "this" {
  for_each = var.nfs_locations

  server_hostname = each.value.server_hostname
  subdirectory    = each.value.subdirectory

  on_prem_config {
    agent_arns = each.value.agent_arns
  }

  dynamic "mount_options" {
    for_each = each.value.mount_options != null ? [each.value.mount_options] : []
    content {
      version = mount_options.value.version
    }
  }

  tags = merge(local.tags, { LocationType = "NFS", LocationKey = each.key })
}

# ── SMB ───────────────────────────────────────────────────────────────────────
data "aws_secretsmanager_secret_version" "smb" {
  for_each  = var.smb_locations
  secret_id = each.value.password_secret_arn
}

resource "aws_datasync_location_smb" "this" {
  for_each = var.smb_locations

  server_hostname = each.value.server_hostname
  subdirectory    = each.value.subdirectory
  domain          = each.value.domain
  user            = each.value.user
  password        = data.aws_secretsmanager_secret_version.smb[each.key].secret_string

  agent_arns = each.value.agent_arns

  dynamic "mount_options" {
    for_each = each.value.mount_options != null ? [each.value.mount_options] : []
    content {
      version = mount_options.value.version
    }
  }

  tags = merge(local.tags, { LocationType = "SMB", LocationKey = each.key })
}

# ── FSx for Windows ───────────────────────────────────────────────────────────
data "aws_secretsmanager_secret_version" "fsx_windows" {
  for_each  = var.fsx_windows_locations
  secret_id = each.value.password_secret_arn
}

resource "aws_datasync_location_fsx_windows_file_system" "this" {
  for_each = var.fsx_windows_locations

  fsx_filesystem_arn  = each.value.fsx_filesystem_arn
  subdirectory        = each.value.subdirectory
  domain              = each.value.domain
  user                = each.value.user
  password            = data.aws_secretsmanager_secret_version.fsx_windows[each.key].secret_string
  security_group_arns = each.value.security_group_arns

  tags = merge(local.tags, { LocationType = "FSxWindows", LocationKey = each.key })
}

# ── FSx for Lustre ────────────────────────────────────────────────────────────
resource "aws_datasync_location_fsx_lustre_file_system" "this" {
  for_each = var.fsx_lustre_locations

  fsx_filesystem_arn  = each.value.fsx_filesystem_arn
  subdirectory        = each.value.subdirectory
  security_group_arns = each.value.security_group_arns

  tags = merge(local.tags, { LocationType = "FSxLustre", LocationKey = each.key })
}

# ── FSx for OpenZFS ───────────────────────────────────────────────────────────
resource "aws_datasync_location_fsx_openzfs_file_system" "this" {
  for_each = var.fsx_openzfs_locations

  fsx_filesystem_arn  = each.value.fsx_filesystem_arn
  subdirectory        = each.value.subdirectory
  security_group_arns = each.value.security_group_arns

  dynamic "protocol" {
    for_each = each.value.protocol != null ? [each.value.protocol] : [{}]
    content {
      dynamic "nfs" {
        for_each = protocol.value.nfs != null ? [protocol.value.nfs] : [{}]
        content {
          dynamic "mount_options" {
            for_each = nfs.value.mount_options != null ? [nfs.value.mount_options] : [{}]
            content {
              version = mount_options.value.version
            }
          }
        }
      }
    }
  }

  tags = merge(local.tags, { LocationType = "FSxOpenZFS", LocationKey = each.key })
}

# ── Object Storage ────────────────────────────────────────────────────────────
data "aws_secretsmanager_secret_version" "object_storage" {
  for_each  = var.object_storage_locations
  secret_id = each.value.secret_key_secret_arn
}

resource "aws_datasync_location_object_storage" "this" {
  for_each = var.object_storage_locations

  server_hostname = each.value.server_hostname
  bucket_name     = each.value.bucket_name
  subdirectory    = each.value.subdirectory
  server_port     = each.value.server_port
  server_protocol = each.value.server_protocol
  access_key      = each.value.access_key
  secret_key      = data.aws_secretsmanager_secret_version.object_storage[each.key].secret_string
  agent_arns      = each.value.agent_arns

  tags = merge(local.tags, { LocationType = "ObjectStorage", LocationKey = each.key })
}

# ── HDFS ──────────────────────────────────────────────────────────────────────
resource "aws_datasync_location_hdfs" "this" {
  for_each = var.hdfs_locations

  dynamic "name_node" {
    for_each = each.value.name_nodes
    content {
      hostname = name_node.value.hostname
      port     = name_node.value.port
    }
  }

  subdirectory        = each.value.subdirectory
  agent_arns          = each.value.agent_arns
  authentication_type = each.value.authentication_type
  simple_user         = each.value.authentication_type == "SIMPLE" ? each.value.simple_user : null
  kerberos_principal  = each.value.authentication_type == "KERBEROS" ? each.value.kerberos_principal : null
  kerberos_keytab     = each.value.authentication_type == "KERBEROS" ? each.value.kerberos_keytab : null
  kerberos_krb5_conf  = each.value.authentication_type == "KERBEROS" ? each.value.kerberos_krb5_conf : null
  block_size          = each.value.block_size
  replication_factor  = each.value.replication_factor

  tags = merge(local.tags, { LocationType = "HDFS", LocationKey = each.key })
}
