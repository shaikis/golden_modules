resource "aws_sagemaker_domain" "this" {
  for_each = var.create_domains ? var.domains : {}

  domain_name = "${local.name_prefix}${each.key}"
  auth_mode   = each.value.auth_mode
  vpc_id      = each.value.vpc_id
  subnet_ids  = each.value.subnet_ids

  default_user_settings {
    execution_role = local.role_arn
  }

  app_network_access_type = each.value.app_network_access_type

  tags = merge(local.tags, each.value.tags)
}
