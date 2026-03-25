resource "aws_athena_data_catalog" "this" {
  for_each = var.data_catalogs

  name        = each.key
  type        = each.value.type
  description = each.value.description
  parameters  = each.value.parameters

  tags = merge(var.tags, each.value.tags)
}
