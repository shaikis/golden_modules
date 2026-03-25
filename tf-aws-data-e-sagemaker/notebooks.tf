# ---------------------------------------------------------------------------
# SageMaker Studio — User Profiles
# ---------------------------------------------------------------------------

resource "aws_sagemaker_user_profile" "this" {
  for_each = var.create_user_profiles ? var.user_profiles : {}

  domain_id         = aws_sagemaker_domain.this[each.value.domain_key].id
  user_profile_name = each.key

  user_settings {
    execution_role  = each.value.execution_role_arn != null ? each.value.execution_role_arn : local.effective_role_arn
    security_groups = each.value.security_group_ids

    sharing_settings {
      notebook_output_option = "Disabled"
    }
  }

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}
