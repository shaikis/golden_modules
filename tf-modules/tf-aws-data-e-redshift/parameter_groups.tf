resource "aws_redshift_parameter_group" "this" {
  for_each = var.create_parameter_groups ? var.parameter_groups : {}

  name        = coalesce(each.value.name, "${each.key}-redshift-pg")
  family      = each.value.family
  description = each.value.description

  dynamic "parameter" {
    for_each = each.value.parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name = coalesce(each.value.name, "${each.key}-redshift-pg")
  })
}
