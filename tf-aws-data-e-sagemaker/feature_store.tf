# ---------------------------------------------------------------------------
# SageMaker Feature Store — Feature Groups
# ---------------------------------------------------------------------------

resource "aws_sagemaker_feature_group" "this" {
  for_each = var.create_feature_groups ? var.feature_groups : {}

  feature_group_name             = each.key
  record_identifier_feature_name = each.value.record_identifier_feature_name
  event_time_feature_name        = each.value.event_time_feature_name
  role_arn                       = each.value.role_arn != null ? each.value.role_arn : local.effective_role_arn

  dynamic "feature_definition" {
    for_each = each.value.features
    content {
      feature_name = feature_definition.value.name
      feature_type = feature_definition.value.type
    }
  }

  dynamic "online_store_config" {
    for_each = each.value.online_store_enabled ? [1] : []
    content {
      enable_online_store = true

      dynamic "security_config" {
        for_each = each.value.online_store_kms_key_id != null ? [1] : (var.kms_key_arn != null ? [1] : [])
        content {
          kms_key_id = each.value.online_store_kms_key_id != null ? each.value.online_store_kms_key_id : var.kms_key_arn
        }
      }
    }
  }

  dynamic "offline_store_config" {
    for_each = each.value.offline_store_bucket != null ? [1] : []
    content {
      disable_glue_table_creation = each.value.disable_glue_table_creation

      s3_storage_config {
        s3_uri     = "s3://${each.value.offline_store_bucket}/${each.value.offline_store_prefix != null ? each.value.offline_store_prefix : each.key}"
        kms_key_id = var.kms_key_arn
      }

      data_catalog_config {
        table_name = replace(each.key, "-", "_")
        database   = "sagemaker_featurestore"
        catalog    = "AwsDataCatalog"
      }

      table_format = each.value.offline_table_format
    }
  }

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}
