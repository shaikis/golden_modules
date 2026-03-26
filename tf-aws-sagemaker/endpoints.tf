resource "aws_sagemaker_endpoint_configuration" "this" {
  for_each = var.create_endpoints ? var.endpoint_configs : {}

  name        = "${local.name_prefix}${each.key}"
  kms_key_arn = var.kms_key_arn

  dynamic "production_variants" {
    for_each = each.value.production_variants
    content {
      variant_name           = production_variants.value.variant_name
      model_name             = production_variants.value.model_name
      instance_type          = production_variants.value.instance_type
      initial_instance_count = production_variants.value.initial_instance_count
      initial_variant_weight = production_variants.value.initial_variant_weight
    }
  }

  tags = merge(local.tags, each.value.tags)
}

resource "aws_sagemaker_endpoint" "this" {
  for_each = var.create_endpoints ? var.endpoints : {}

  name                 = "${local.name_prefix}${each.key}"
  endpoint_config_name = each.value.endpoint_config_name

  tags = merge(local.tags, each.value.tags)
}
