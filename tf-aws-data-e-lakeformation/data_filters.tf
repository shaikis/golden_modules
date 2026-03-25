resource "aws_lakeformation_data_cells_filter" "this" {
  for_each = var.create_data_filters ? var.data_cell_filters : {}

  table_data {
    table_catalog_id = coalesce(each.value.table_catalog_id, data.aws_caller_identity.current.account_id)
    database_name    = each.value.database_name
    table_name       = each.value.table_name
    name             = each.value.name

    dynamic "row_filter" {
      for_each = each.value.row_filter_expression != null ? [1] : []
      content {
        filter_expression = each.value.row_filter_expression
      }
    }

    dynamic "row_filter" {
      for_each = each.value.row_filter_expression == null ? [1] : []
      content {
        all_rows_wildcard {}
      }
    }

    dynamic "column_wildcard" {
      for_each = length(each.value.column_names) == 0 && length(each.value.excluded_column_names) == 0 ? [1] : []
      content {}
    }

    column_names = length(each.value.column_names) > 0 ? each.value.column_names : null

    dynamic "column_wildcard" {
      for_each = length(each.value.excluded_column_names) > 0 ? [1] : []
      content {
        excluded_column_names = each.value.excluded_column_names
      }
    }
  }

  depends_on = [aws_lakeformation_data_lake_settings.this]
}
