resource "aws_athena_workgroup" "this" {
  for_each = var.workgroups

  name          = each.key
  description   = each.value.description
  state         = each.value.state
  force_destroy = each.value.force_destroy

  configuration {
    enforce_workgroup_configuration    = each.value.enforce_workgroup_configuration
    publish_cloudwatch_metrics_enabled = each.value.publish_cloudwatch_metrics_enabled
    bytes_scanned_cutoff_per_query     = each.value.bytes_scanned_cutoff_per_query
    requester_pays_enabled             = each.value.requester_pays_enabled

    engine_version {
      selected_engine_version = each.value.engine_version
    }

    dynamic "result_configuration" {
      for_each = each.value.result_configuration != null ? [each.value.result_configuration] : []

      content {
        output_location       = result_configuration.value.output_location
        expected_bucket_owner = result_configuration.value.expected_bucket_owner

        encryption_configuration {
          encryption_option = result_configuration.value.encryption_type
          kms_key           = result_configuration.value.kms_key_arn
        }

        dynamic "acl_configuration" {
          for_each = result_configuration.value.s3_acl_option != null ? [result_configuration.value.s3_acl_option] : []

          content {
            s3_acl_option = acl_configuration.value
          }
        }
      }
    }
  }

  tags = merge(var.tags, each.value.tags)
}
