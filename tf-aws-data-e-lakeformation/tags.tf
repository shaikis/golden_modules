resource "aws_lakeformation_lf_tag" "this" {
  for_each = var.create_lf_tags ? var.lf_tags : {}

  key    = each.key
  values = each.value.values

  depends_on = [aws_lakeformation_data_lake_settings.this]
}

resource "aws_lakeformation_permissions" "lf_tag_policy" {
  for_each = var.create_lf_tags ? var.lf_tag_policies : {}

  principal                     = each.value.principal
  permissions                   = each.value.permissions
  permissions_with_grant_option = each.value.permissions_with_grant_option
  catalog_id                    = each.value.catalog_id

  lf_tag_policy {
    resource_type = each.value.resource_type
    catalog_id    = each.value.catalog_id

    dynamic "expression" {
      for_each = each.value.expression
      content {
        key    = expression.value.key
        values = expression.value.values
      }
    }
  }

  depends_on = [
    aws_lakeformation_data_lake_settings.this,
    aws_lakeformation_lf_tag.this,
  ]
}
