# ── Configuration Sets ─────────────────────────────────────────────────────────

resource "aws_sesv2_configuration_set" "this" {
  for_each = var.create_configuration_sets ? var.configuration_sets : {}

  configuration_set_name = each.key

  sending_options {
    sending_enabled = each.value.sending_enabled
  }

  reputation_options {
    reputation_metrics_enabled = each.value.reputation_metrics_enabled
  }

  suppression_options {
    suppressed_reasons = each.value.suppression_reasons
  }

  dynamic "tracking_options" {
    for_each = each.value.custom_redirect_domain != null ? [1] : []
    content {
      custom_redirect_domain = each.value.custom_redirect_domain
    }
  }

  vdm_options {
    dashboard_options {
      engagement_metrics = each.value.engagement_metrics ? "ENABLED" : "DISABLED"
    }
    guardian_options {
      optimized_shared_delivery = each.value.optimized_shared_delivery ? "ENABLED" : "DISABLED"
    }
  }

  tags = merge(var.tags, each.value.tags)
}

# ── Event Destinations ─────────────────────────────────────────────────────────
# Flatten the nested map: configuration_set_key + destination_key → unique resource key

locals {
  # Build a flat map of all event destinations across all configuration sets.
  # Only populated when create_configuration_sets is true.
  event_destinations_flat = var.create_configuration_sets ? merge([
    for cs_key, cs in var.configuration_sets : {
      for dest_key, dest in cs.event_destinations :
      "${cs_key}__${dest_key}" => merge(dest, {
        configuration_set_name = cs_key
        destination_name       = dest_key
      })
    }
  ]...) : {}
}

resource "aws_sesv2_configuration_set_event_destination" "this" {
  for_each = var.create_configuration_sets ? local.event_destinations_flat : {}

  configuration_set_name = each.value.configuration_set_name
  event_destination_name = each.value.destination_name

  event_destination {
    enabled              = each.value.enabled
    matching_event_types = each.value.event_types

    dynamic "sns_destination" {
      for_each = each.value.sns_destination != null ? [each.value.sns_destination] : []
      content {
        topic_arn = sns_destination.value.topic_arn
      }
    }

    dynamic "cloud_watch_destination" {
      for_each = each.value.cloudwatch_destination != null ? [each.value.cloudwatch_destination] : []
      content {
        dynamic "dimension_configuration" {
          for_each = cloud_watch_destination.value.dimension_configurations
          content {
            dimension_name          = dimension_configuration.value.dimension_name
            dimension_value_source  = dimension_configuration.value.dimension_value_source
            default_dimension_value = dimension_configuration.value.default_dimension_value
          }
        }
      }
    }

    dynamic "kinesis_firehose_destination" {
      for_each = each.value.kinesis_firehose_destination != null ? [each.value.kinesis_firehose_destination] : []
      content {
        delivery_stream_arn = kinesis_firehose_destination.value.delivery_stream_arn
        iam_role_arn = (
          kinesis_firehose_destination.value.iam_role_arn != null
          ? kinesis_firehose_destination.value.iam_role_arn
          : (var.create_iam_roles || var.create_firehose_role ? aws_iam_role.ses_firehose[0].arn : null)
        )
      }
    }

    dynamic "pinpoint_destination" {
      for_each = each.value.pinpoint_destination != null ? [each.value.pinpoint_destination] : []
      content {
        application_arn = pinpoint_destination.value.application_arn
      }
    }
  }

  depends_on = [aws_sesv2_configuration_set.this]
}
