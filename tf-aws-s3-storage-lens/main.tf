data "aws_caller_identity" "current" {}

locals {
  effective_account_id = coalesce(var.account_id, data.aws_caller_identity.current.account_id)
}

resource "aws_s3control_storage_lens_configuration" "this" {
  account_id = local.effective_account_id
  config_id  = var.config_id
  tags       = var.tags

  storage_lens_configuration {
    enabled = var.enabled

    account_level {
      dynamic "activity_metrics" {
        for_each = var.account_level.activity_metrics != null ? [var.account_level.activity_metrics] : []
        content {
          enabled = activity_metrics.value
        }
      }

      dynamic "advanced_cost_optimization_metrics" {
        for_each = var.account_level.advanced_cost_optimization_metrics != null ? [var.account_level.advanced_cost_optimization_metrics] : []
        content {
          enabled = advanced_cost_optimization_metrics.value
        }
      }

      dynamic "advanced_data_protection_metrics" {
        for_each = var.account_level.advanced_data_protection_metrics != null ? [var.account_level.advanced_data_protection_metrics] : []
        content {
          enabled = advanced_data_protection_metrics.value
        }
      }

      dynamic "detailed_status_code_metrics" {
        for_each = var.account_level.detailed_status_code_metrics != null ? [var.account_level.detailed_status_code_metrics] : []
        content {
          enabled = detailed_status_code_metrics.value
        }
      }

      bucket_level {
        dynamic "activity_metrics" {
          for_each = try(var.account_level.bucket_level.activity_metrics, null) != null ? [var.account_level.bucket_level.activity_metrics] : []
          content {
            enabled = activity_metrics.value
          }
        }

        dynamic "advanced_cost_optimization_metrics" {
          for_each = try(var.account_level.bucket_level.advanced_cost_optimization_metrics, null) != null ? [var.account_level.bucket_level.advanced_cost_optimization_metrics] : []
          content {
            enabled = advanced_cost_optimization_metrics.value
          }
        }

        dynamic "advanced_data_protection_metrics" {
          for_each = try(var.account_level.bucket_level.advanced_data_protection_metrics, null) != null ? [var.account_level.bucket_level.advanced_data_protection_metrics] : []
          content {
            enabled = advanced_data_protection_metrics.value
          }
        }

        dynamic "detailed_status_code_metrics" {
          for_each = try(var.account_level.bucket_level.detailed_status_code_metrics, null) != null ? [var.account_level.bucket_level.detailed_status_code_metrics] : []
          content {
            enabled = detailed_status_code_metrics.value
          }
        }

        dynamic "prefix_level" {
          for_each = try(var.account_level.bucket_level.prefix_level, null) != null ? [var.account_level.bucket_level.prefix_level] : []
          content {
            storage_metrics {
              enabled = prefix_level.value.storage_metrics.enabled

              dynamic "selection_criteria" {
                for_each = prefix_level.value.storage_metrics.selection_criteria != null ? [prefix_level.value.storage_metrics.selection_criteria] : []
                content {
                  delimiter                    = selection_criteria.value.delimiter
                  max_depth                    = selection_criteria.value.max_depth
                  min_storage_bytes_percentage = selection_criteria.value.min_storage_bytes_percentage
                }
              }
            }
          }
        }
      }
    }

    dynamic "include" {
      for_each = var.include != null ? [var.include] : []
      content {
        buckets = include.value.buckets
        regions = include.value.regions
      }
    }

    dynamic "exclude" {
      for_each = var.exclude != null ? [var.exclude] : []
      content {
        buckets = exclude.value.buckets
        regions = exclude.value.regions
      }
    }

    dynamic "data_export" {
      for_each = var.data_export != null ? [var.data_export] : []
      content {
        dynamic "cloud_watch_metrics" {
          for_each = data_export.value.cloud_watch_metrics_enabled != null ? [data_export.value.cloud_watch_metrics_enabled] : []
          content {
            enabled = cloud_watch_metrics.value
          }
        }

        dynamic "s3_bucket_destination" {
          for_each = data_export.value.s3_bucket_destination != null ? [data_export.value.s3_bucket_destination] : []
          content {
            account_id            = coalesce(s3_bucket_destination.value.account_id, local.effective_account_id)
            arn                   = s3_bucket_destination.value.arn
            format                = s3_bucket_destination.value.format
            output_schema_version = s3_bucket_destination.value.output_schema_version
            prefix                = s3_bucket_destination.value.prefix

            dynamic "encryption" {
              for_each = s3_bucket_destination.value.encryption != null ? [s3_bucket_destination.value.encryption] : []
              content {
                dynamic "sse_kms" {
                  for_each = encryption.value.type == "SSE-KMS" ? [encryption.value] : []
                  content {
                    key_id = sse_kms.value.key_id
                  }
                }

                dynamic "sse_s3" {
                  for_each = encryption.value.type == "SSE-S3" ? [encryption.value] : []
                  content {}
                }
              }
            }
          }
        }
      }
    }
  }
}
