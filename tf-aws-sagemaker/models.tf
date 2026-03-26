resource "aws_sagemaker_model" "this" {
  for_each = var.create_models ? var.models : {}

  name               = "${local.name_prefix}${each.key}"
  execution_role_arn = coalesce(each.value.execution_role_arn, local.role_arn)

  primary_container {
    image          = each.value.primary_container_image
    model_data_url = each.value.model_data_url
    environment    = each.value.environment
  }

  tags = merge(local.tags, each.value.tags)
}
