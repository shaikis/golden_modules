resource "aws_sagemaker_feature_group" "this" {
  for_each = var.create_feature_groups ? var.feature_groups : {}

  feature_group_name             = "${local.name_prefix}${each.key}"
  record_identifier_feature_name = each.value.record_identifier_name
  event_time_feature_name        = each.value.event_time_feature_name
  role_arn                       = local.role_arn

  dynamic "feature_definition" {
    for_each = each.value.features
    content {
      feature_name = feature_definition.value.name
      feature_type = feature_definition.value.feature_type
    }
  }

  dynamic "online_store_config" {
    for_each = each.value.enable_online_store ? [1] : []
    content {
      enable_online_store = true
    }
  }

  dynamic "offline_store_config" {
    for_each = each.value.enable_offline_store ? [1] : []
    content {
      s3_storage_config {
        s3_uri = each.value.s3_offline_store_uri
      }
    }
  }

  tags = merge(local.tags, each.value.tags)
}
