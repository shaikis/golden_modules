# ---------------------------------------------------------------------------
# SageMaker Models
# ---------------------------------------------------------------------------

resource "aws_sagemaker_model" "this" {
  for_each = var.create_models ? var.models : {}

  name               = each.key
  execution_role_arn = each.value.execution_role_arn != null ? each.value.execution_role_arn : local.effective_role_arn

  enable_network_isolation = each.value.enable_network_isolation

  primary_container {
    image          = each.value.primary_container.image_uri
    model_data_url = each.value.primary_container.model_data_url
    mode           = each.value.primary_container.mode
    environment    = each.value.primary_container.environment
  }

  dynamic "container" {
    for_each = each.value.containers
    content {
      image          = container.value.image_uri
      model_data_url = container.value.model_data_url
      mode           = container.value.mode
      environment    = container.value.environment
    }
  }

  dynamic "vpc_config" {
    for_each = length(each.value.vpc_subnet_ids) > 0 ? [1] : []
    content {
      subnets            = each.value.vpc_subnet_ids
      security_group_ids = each.value.vpc_security_group_ids
    }
  }

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}
