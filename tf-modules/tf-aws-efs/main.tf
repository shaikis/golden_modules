# ---------------------------------------------------------------------------
# Security Group for EFS Mount Targets (optional — disable if bringing your own)
# ---------------------------------------------------------------------------
resource "aws_security_group" "efs" {
  count = var.create && var.create_security_group ? 1 : 0

  name        = "${local.name}-efs-sg"
  description = "Allow NFS (2049) access to EFS mount targets"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = length(var.allowed_cidr_blocks) > 0 ? [1] : []
    content {
      description = "NFS from CIDR blocks"
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      description     = "NFS from security group ${ingress.value}"
      from_port       = 2049
      to_port         = 2049
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-efs-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# EFS File System
# ---------------------------------------------------------------------------
resource "aws_efs_file_system" "this" {
  count = var.create ? 1 : 0

  encrypted        = var.encrypted
  kms_key_id       = var.kms_key_arn
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode

  provisioned_throughput_in_mibps = (
    var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null
  )

  # Move files to IA storage after N days without access
  dynamic "lifecycle_policy" {
    for_each = (
      var.enable_lifecycle_policy && var.transition_to_ia != null
      ? [var.transition_to_ia]
      : []
    )
    content {
      transition_to_ia = lifecycle_policy.value
    }
  }

  # Move files back to primary storage when accessed
  dynamic "lifecycle_policy" {
    for_each = (
      var.enable_lifecycle_policy && var.transition_to_primary_storage_class != null
      ? [var.transition_to_primary_storage_class]
      : []
    )
    content {
      transition_to_primary_storage_class = lifecycle_policy.value
    }
  }

  tags = merge(local.tags, { Name = local.name })

  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------------------------------------------------------
# AWS Backup Policy (optional — disable if managing backups externally)
# ---------------------------------------------------------------------------
resource "aws_efs_backup_policy" "this" {
  count = var.create && var.enable_backup_policy ? 1 : 0

  file_system_id = aws_efs_file_system.this[0].id

  backup_policy {
    status = "ENABLED"
  }
}

# ---------------------------------------------------------------------------
# Mount Targets — one per subnet/AZ for HA
# ---------------------------------------------------------------------------
resource "aws_efs_mount_target" "this" {
  for_each = var.create ? toset(var.subnet_ids) : toset([])

  file_system_id = aws_efs_file_system.this[0].id
  subnet_id      = each.value

  security_groups = concat(
    var.create_security_group ? [aws_security_group.efs[0].id] : [],
    var.security_group_ids
  )
}

# ---------------------------------------------------------------------------
# Access Points (optional — define app-specific entry points)
# ---------------------------------------------------------------------------
resource "aws_efs_access_point" "this" {
  for_each = var.create ? var.access_points : {}

  file_system_id = aws_efs_file_system.this[0].id

  root_directory {
    path = each.value.path
    creation_info {
      owner_uid   = each.value.owner_uid
      owner_gid   = each.value.owner_gid
      permissions = each.value.permissions
    }
  }

  posix_user {
    uid            = each.value.posix_uid
    gid            = each.value.posix_gid
    secondary_gids = each.value.secondary_gids
  }

  tags = merge(local.tags, { Name = "${local.name}-ap-${each.key}" })
}

# ---------------------------------------------------------------------------
# Cross-Region Replication (optional — enable for DR/multi-region workloads)
# NOTE: AWS automatically creates the destination EFS file system.
#       You do NOT need to pre-create it. Disabling this resource will
#       delete the replication but leave the destination FS intact.
# ---------------------------------------------------------------------------
resource "aws_efs_replication_configuration" "this" {
  count = var.create && var.enable_replication ? 1 : 0

  source_file_system_id = aws_efs_file_system.this[0].id

  destination {
    region                 = var.replication_destination_region
    kms_key_id             = var.replication_destination_kms_key_arn
    availability_zone_name = var.replication_destination_availability_zone
  }
}
