resource "aws_lakeformation_resource_lf_tags" "this" {
  for_each = var.create_governed_tables ? var.resource_lf_tags : {}

  catalog_id = each.value.catalog_id

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

  dynamic "lf_tag" {
    for_each = each.value.lf_tags
    content {
      key        = lf_tag.value.key
      value      = lf_tag.value.value
      catalog_id = lf_tag.value.catalog_id
    }
  }

  depends_on = [
    aws_lakeformation_data_lake_settings.this,
    aws_lakeformation_lf_tag.this,
  ]
}
