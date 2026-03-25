locals {
  # ---------------------------------------------------------------------------
  # Pre-built common query templates.
  # Replace {table} with the actual table name when constructing a query value.
  # ---------------------------------------------------------------------------
  query_templates = {
    preview_table       = "SELECT * FROM {table} LIMIT 10;"
    count_rows          = "SELECT COUNT(*) FROM {table};"
    partition_discovery = "MSCK REPAIR TABLE {table};"
    show_partitions     = "SHOW PARTITIONS {table};"
    optimize_table      = "OPTIMIZE {table} REWRITE DATA USING BIN_PACK;"
    vacuum_table        = "VACUUM {table};"
  }
}

resource "aws_athena_named_query" "this" {
  for_each = var.named_queries

  name        = each.value.name
  description = each.value.description
  database    = each.value.database
  workgroup   = each.value.workgroup
  query       = each.value.query
}
