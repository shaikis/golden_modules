# ---------------------------------------------------------------------------
# DynamoDB Contributor Insights
# ---------------------------------------------------------------------------

locals {
  # Tables with contributor_insights = true
  ci_tables = {
    for k, v in var.tables : k => v
    if v.contributor_insights
  }

  # Flatten table → GSI pairs for GSI-level contributor insights
  ci_gsi_pairs = merge([
    for table_key, table in local.ci_tables : {
      for gsi in table.global_secondary_indexes :
      "${table_key}__${gsi.name}" => {
        table_key = table_key
        gsi_name  = gsi.name
      }
    }
  ]...)
}

# Table-level Contributor Insights
resource "aws_dynamodb_contributor_insights" "table" {
  for_each = local.ci_tables

  table_name = aws_dynamodb_table.this[each.key].name
}

# GSI-level Contributor Insights
resource "aws_dynamodb_contributor_insights" "gsi" {
  for_each = local.ci_gsi_pairs

  table_name = aws_dynamodb_table.this[each.value.table_key].name
  index_name = each.value.gsi_name
}
