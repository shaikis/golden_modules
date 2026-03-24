resource "aws_lakeformation_permissions" "this" {
  for_each = var.create_permissions ? var.permissions : {}

  principal                     = each.value.principal
  permissions                   = each.value.permissions
  permissions_with_grant_option = each.value.permissions_with_grant_option
  catalog_id                    = each.value.catalog_id

  dynamic "database" {
    for_each = each.value.database != null ? [each.value.database] : []
    content {
      name       = database.value.name
      catalog_id = database.value.catalog_id
    }
  }

  dynamic "table" {
    for_each = each.value.table != null ? [each.value.table] : []
    content {
      database_name = table.value.database_name
      name          = table.value.wildcard ? null : table.value.name
      wildcard      = table.value.wildcard
      catalog_id    = table.value.catalog_id
    }
  }

  dynamic "table_with_columns" {
    for_each = each.value.table_with_columns != null ? [each.value.table_with_columns] : []
    content {
      database_name         = table_with_columns.value.database_name
      name                  = table_with_columns.value.name
      column_names          = length(table_with_columns.value.column_names) > 0 ? table_with_columns.value.column_names : null
      excluded_column_names = length(table_with_columns.value.excluded_column_names) > 0 ? table_with_columns.value.excluded_column_names : null
      catalog_id            = table_with_columns.value.catalog_id

      dynamic "column_wildcard" {
        for_each = table_with_columns.value.wildcard ? [1] : []
        content {}
      }
    }
  }

  dynamic "data_location" {
    for_each = each.value.data_location != null ? [each.value.data_location] : []
    content {
      arn        = data_location.value.arn
      catalog_id = data_location.value.catalog_id
    }
  }

  dynamic "lf_tag" {
    for_each = each.value.lf_tag != null ? [each.value.lf_tag] : []
    content {
      key    = lf_tag.value.key
      values = lf_tag.value.values
    }
  }

  dynamic "lf_tag_policy" {
    for_each = each.value.lf_tag_policy != null ? [each.value.lf_tag_policy] : []
    content {
      resource_type = lf_tag_policy.value.resource_type
      catalog_id    = lf_tag_policy.value.catalog_id

      dynamic "expression" {
        for_each = lf_tag_policy.value.expression
        content {
          key    = expression.value.key
          values = expression.value.values
        }
      }
    }
  }

  depends_on = [
    aws_lakeformation_data_lake_settings.this,
    aws_lakeformation_resource.this,
    aws_lakeformation_lf_tag.this,
  ]
}
