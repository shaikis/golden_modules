# ---------------------------------------------------------------------------
# Custom Parameter Group
# ---------------------------------------------------------------------------
resource "aws_db_parameter_group" "this" {
  count = var.create_parameter_group ? 1 : 0

  name        = "${local.name}-pg"
  family      = var.parameter_group_family
  description = "Parameter group for ${local.name}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}
