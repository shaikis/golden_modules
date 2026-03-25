resource "aws_redshiftserverless_namespace" "this" {
  for_each = var.create_serverless ? var.serverless_namespaces : {}

  namespace_name        = each.key
  db_name               = each.value.db_name
  admin_username        = each.value.admin_username
  manage_admin_password = each.value.manage_admin_password
  admin_user_password   = each.value.manage_admin_password ? null : each.value.admin_user_password
  kms_key_id            = coalesce(each.value.kms_key_id, var.kms_key_arn)
  log_exports           = each.value.log_exports
  iam_roles             = each.value.iam_role_arns

  tags = merge(var.tags, each.value.tags, {
    Name = each.key
  })
}

resource "aws_redshiftserverless_workgroup" "this" {
  for_each = var.create_serverless ? var.serverless_workgroups : {}

  workgroup_name       = each.key
  namespace_name       = aws_redshiftserverless_namespace.this[each.value.namespace_key].namespace_name
  base_capacity        = each.value.base_capacity
  max_capacity         = each.value.max_capacity
  subnet_ids           = each.value.subnet_ids
  security_group_ids   = each.value.security_group_ids
  publicly_accessible  = each.value.publicly_accessible
  enhanced_vpc_routing = each.value.enhanced_vpc_routing

  dynamic "config_parameter" {
    for_each = each.value.config_parameters
    content {
      parameter_key   = config_parameter.key
      parameter_value = config_parameter.value
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name = each.key
  })

  depends_on = [aws_redshiftserverless_namespace.this]
}
