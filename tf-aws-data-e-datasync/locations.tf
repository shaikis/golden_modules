# ---------------------------------------------------------------------------
# DataSync Locations
# ---------------------------------------------------------------------------

# ── S3 Locations ─────────────────────────────────────────────────────────────

resource "aws_datasync_location_s3" "this" {
  for_each = var.create_s3_locations ? var.s3_locations : {}

  s3_bucket_arn    = each.value.s3_bucket_arn
  subdirectory     = each.value.subdirectory
  s3_storage_class = each.value.s3_storage_class

  s3_config {
    bucket_access_role_arn = each.value.bucket_access_role_arn != null ? each.value.bucket_access_role_arn : local.effective_role_arn
  }

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}

# ── EFS Locations ─────────────────────────────────────────────────────────────

resource "aws_datasync_location_efs" "this" {
  for_each = var.create_efs_locations ? var.efs_locations : {}

  efs_file_system_arn   = each.value.efs_file_system_arn
  subdirectory          = each.value.subdirectory
  in_transit_encryption = each.value.in_transit_encryption

  ec2_config {
    subnet_arn          = each.value.ec2_subnet_arn
    security_group_arns = each.value.ec2_security_group_arns
  }

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}

# ── FSx for Windows Locations ─────────────────────────────────────────────────

resource "aws_datasync_location_fsx_windows_file_system" "this" {
  for_each = var.create_fsx_windows_locations ? var.fsx_windows_locations : {}

  fsx_filesystem_arn  = each.value.fsx_filesystem_arn
  security_group_arns = each.value.security_group_arns
  user                = each.value.user
  password            = each.value.password
  domain              = each.value.domain
  subdirectory        = each.value.subdirectory

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}

# ── FSx for Lustre Locations ──────────────────────────────────────────────────

resource "aws_datasync_location_fsx_lustre_file_system" "this" {
  for_each = var.create_fsx_lustre_locations ? var.fsx_lustre_locations : {}

  fsx_filesystem_arn  = each.value.fsx_filesystem_arn
  security_group_arns = each.value.security_group_arns
  subdirectory        = each.value.subdirectory

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}

# ── NFS Locations ─────────────────────────────────────────────────────────────

resource "aws_datasync_location_nfs" "this" {
  for_each = var.create_nfs_locations ? var.nfs_locations : {}

  server_hostname = each.value.server_hostname
  subdirectory    = each.value.subdirectory

  on_prem_config {
    agent_arns = each.value.agent_arns
  }

  mount_options {
    version = each.value.mount_version
  }

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}

# ── SMB Locations ─────────────────────────────────────────────────────────────

resource "aws_datasync_location_smb" "this" {
  for_each = var.create_smb_locations ? var.smb_locations : {}

  server_hostname = each.value.server_hostname
  subdirectory    = each.value.subdirectory
  user            = each.value.user
  password        = each.value.password
  domain          = each.value.domain
  agent_arns      = each.value.agent_arns

  mount_options {
    version = each.value.mount_version
  }

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}

# ── HDFS Locations ────────────────────────────────────────────────────────────

resource "aws_datasync_location_hdfs" "this" {
  for_each = var.create_hdfs_locations ? var.hdfs_locations : {}

  subdirectory       = each.value.subdirectory
  agent_arns         = each.value.agent_arns
  replication_factor = each.value.replication_factor
  authentication_type = each.value.auth_type
  simple_user        = each.value.simple_user

  dynamic "name_node" {
    for_each = each.value.name_nodes
    content {
      hostname = name_node.value.hostname
      port     = name_node.value.port
    }
  }

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}

# ── Object Storage Locations ──────────────────────────────────────────────────

resource "aws_datasync_location_object_storage" "this" {
  for_each = var.create_object_storage_locations ? var.object_storage_locations : {}

  server_hostname  = each.value.server_hostname
  bucket_name      = each.value.bucket_name
  server_protocol  = each.value.server_protocol
  server_port      = each.value.server_port
  subdirectory     = each.value.subdirectory
  agent_arns       = each.value.agent_arns
  access_key       = each.value.access_key
  secret_key       = each.value.secret_key

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}
