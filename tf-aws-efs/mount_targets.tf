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
