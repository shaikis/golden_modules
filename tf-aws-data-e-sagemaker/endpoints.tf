# ---------------------------------------------------------------------------
# SageMaker Endpoint Configurations & Endpoints
# ---------------------------------------------------------------------------

resource "aws_sagemaker_endpoint_configuration" "this" {
  for_each = var.create_endpoints ? var.endpoint_configurations : {}

  name        = each.key
  kms_key_arn = each.value.kms_key_arn != null ? each.value.kms_key_arn : var.kms_key_arn

  dynamic "production_variants" {
    for_each = each.value.production_variants
    content {
      variant_name           = production_variants.value.variant_name
      model_name             = var.create_models ? aws_sagemaker_model.this[production_variants.value.model_key].name : production_variants.value.model_key
      instance_type          = production_variants.value.instance_type
      initial_instance_count = production_variants.value.initial_instance_count
      initial_variant_weight = production_variants.value.initial_variant_weight
    }
  }

  dynamic "data_capture_config" {
    for_each = each.value.data_capture_enabled ? [1] : []
    content {
      enable_capture              = true
      destination_s3_uri          = each.value.data_capture_s3_uri
      initial_sampling_percentage = each.value.data_capture_sample_percentage

      dynamic "capture_options" {
        for_each = each.value.data_capture_options
        content {
          capture_mode = capture_options.value
        }
      }

      capture_content_type_header {
        json_content_types = ["application/json"]
      }
    }
  }

  dynamic "async_inference_config" {
    for_each = each.value.async_inference_enabled ? [1] : []
    content {
      output_config {
        s3_output_path  = each.value.async_output_s3_uri
        s3_failure_path = each.value.async_failure_s3_uri
        kms_key_id      = each.value.kms_key_arn != null ? each.value.kms_key_arn : var.kms_key_arn
      }

      dynamic "client_config" {
        for_each = each.value.async_max_concurrent_invocations != null ? [1] : []
        content {
          max_concurrent_invocations_per_instance = each.value.async_max_concurrent_invocations
        }
      }
    }
  }

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}

resource "aws_sagemaker_endpoint" "this" {
  for_each = var.create_endpoints ? var.endpoints : {}

  name                 = each.key
  endpoint_config_name = aws_sagemaker_endpoint_configuration.this[each.value.endpoint_config_key].name

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}
