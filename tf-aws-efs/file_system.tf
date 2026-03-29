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

  encrypted              = var.encrypted
  kms_key_id             = var.kms_key_arn
  performance_mode       = var.performance_mode
  throughput_mode        = var.throughput_mode
  availability_zone_name = var.availability_zone_name

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

resource "aws_efs_file_system_policy" "this" {
  count = var.create && var.file_system_policy != null ? 1 : 0

  file_system_id                     = aws_efs_file_system.this[0].id
  policy                             = var.file_system_policy
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check
}
