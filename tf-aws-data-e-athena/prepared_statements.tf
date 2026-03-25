resource "aws_athena_prepared_statement" "this" {
  for_each = var.prepared_statements

  name            = each.key
  workgroup       = each.value.workgroup_name
  description     = each.value.description
  query_statement = each.value.query_statement
}
