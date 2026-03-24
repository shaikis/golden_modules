resource "aws_redshift_subnet_group" "this" {
  for_each = var.create_subnet_groups ? var.subnet_groups : {}

  name        = coalesce(each.value.name, "${each.key}-redshift-sg")
  description = each.value.description
  subnet_ids  = each.value.subnet_ids

  tags = merge(var.tags, each.value.tags, {
    Name = coalesce(each.value.name, "${each.key}-redshift-sg")
  })
}
