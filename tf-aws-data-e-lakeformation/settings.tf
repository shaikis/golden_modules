data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_lakeformation_data_lake_settings" "this" {
  admins          = var.data_lake_admins
  readonly_admins = var.readonly_admins

  allow_external_data_filtering      = var.allow_external_data_filtering
  external_data_filtering_allow_list = var.external_data_filtering_allow_list
  authorized_session_tag_value_list  = var.authorized_session_tag_value_list

  dynamic "create_database_default_permissions" {
    for_each = var.create_database_default_permissions
    content {
      principal   = create_database_default_permissions.value.principal
      permissions = create_database_default_permissions.value.permissions
    }
  }

  dynamic "create_table_default_permissions" {
    for_each = var.create_table_default_permissions
    content {
      principal   = create_table_default_permissions.value.principal
      permissions = create_table_default_permissions.value.permissions
    }
  }
}
