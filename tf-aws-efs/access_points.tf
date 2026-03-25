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
