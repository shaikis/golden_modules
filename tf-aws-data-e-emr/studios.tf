###############################################################################
# EMR Studio (Notebook IDE)
###############################################################################

resource "aws_emr_studio" "this" {
  for_each = var.create_studios ? var.studios : {}

  name      = each.key
  auth_mode = each.value.auth_mode

  vpc_id                         = each.value.vpc_id
  subnet_ids                     = each.value.subnet_ids
  workspace_security_group_id    = each.value.workspace_security_group_id
  engine_security_group_id       = each.value.engine_security_group_id
  default_s3_location            = each.value.s3_url
  service_role                   = each.value.service_role_arn != null ? each.value.service_role_arn : (var.create_iam_role ? aws_iam_role.emr_service[0].arn : var.role_arn)
  user_role                      = each.value.user_role_arn
  idp_auth_url                   = each.value.auth_mode == "SSO" ? each.value.idp_auth_url : null
  idp_relay_state_parameter_name = each.value.auth_mode == "SSO" ? each.value.idp_relay_state_parameter_name : null

  tags = merge(var.tags, each.value.tags, {
    Name = each.key
  })
}
