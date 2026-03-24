# ---------------------------------------------------------------------------
# EC2 Instance Profiles
# Created only for roles where create_instance_profile = true
# ---------------------------------------------------------------------------

locals {
  # Filter to only roles that need an instance profile
  instance_profile_roles = {
    for k, v in var.roles : k => v
    if v.create_instance_profile
  }
}

resource "aws_iam_instance_profile" "this" {
  for_each = local.instance_profile_roles

  name = local.role_names[each.key]
  path = each.value.path
  role = aws_iam_role.this[each.key].name

  tags = merge(var.tags, each.value.tags, {
    Name      = local.role_names[each.key]
    ManagedBy = "terraform"
  })
}
