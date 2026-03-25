resource "aws_lakeformation_resource" "this" {
  for_each = var.data_lake_locations

  arn                     = each.value.s3_arn
  use_service_linked_role = each.value.use_service_linked_role
  role_arn                = each.value.use_service_linked_role ? null : coalesce(each.value.role_arn, var.role_arn, try(aws_iam_role.lakeformation[0].arn, null))
  hybrid_access_enabled   = each.value.hybrid_access_enabled
  with_federation         = each.value.with_federation

  depends_on = [aws_lakeformation_data_lake_settings.this]
}
