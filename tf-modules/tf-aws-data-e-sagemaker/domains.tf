# ---------------------------------------------------------------------------
# SageMaker Studio Domains
# ---------------------------------------------------------------------------

resource "aws_sagemaker_domain" "this" {
  for_each = var.domains

  domain_name             = each.key
  auth_mode               = each.value.auth_mode
  vpc_id                  = each.value.vpc_id
  subnet_ids              = each.value.subnet_ids
  app_network_access_type = each.value.app_network_access_type
  kms_key_id              = each.value.kms_key_id != null ? each.value.kms_key_id : var.kms_key_arn

  default_user_settings {
    execution_role  = each.value.execution_role_arn != null ? each.value.execution_role_arn : local.effective_role_arn
    security_groups = each.value.security_group_ids

    sharing_settings {
      notebook_output_option = "Disabled"
    }
  }

  domain_settings {
    security_group_ids = each.value.security_group_ids

    r_studio_server_pro_domain_settings {}
  }

  app_security_group_management = each.value.app_security_group_management

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}
