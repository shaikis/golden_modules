# ---------------------------------------------------------------------------
# Kinesis Data Analytics v2 — Apache Flink
# ---------------------------------------------------------------------------

locals {
  # Applications that need auto-created execution roles.
  # Both maps are empty when create_analytics_applications = false.
  analytics_auto_role = var.create_analytics_applications ? {
    for k, v in var.analytics_applications : k => v
    if v.service_execution_role == null
  } : {}

  # Applications that supply their own role
  analytics_existing_role = var.create_analytics_applications ? {
    for k, v in var.analytics_applications : k => v
    if v.service_execution_role != null
  } : {}
}

# ---------------------------------------------------------------------------
# Flink applications — auto-created role
# ---------------------------------------------------------------------------

resource "aws_kinesisanalyticsv2_application" "auto_role" {
  for_each = local.analytics_auto_role

  name                   = "${var.name_prefix}${each.key}"
  runtime_environment    = each.value.runtime_environment
  service_execution_role = aws_iam_role.analytics[each.key].arn
  description            = each.value.description

  application_configuration {
    application_code_configuration {
      code_content_type = "ZIPFILE"
      code_content {
        s3_content_location {
          bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${each.value.code_s3_bucket}"
          file_key   = each.value.code_s3_key
        }
      }
    }

    flink_application_configuration {
      checkpoint_configuration {
        configuration_type            = "CUSTOM"
        checkpointing_enabled         = each.value.checkpoint_enabled
        checkpoint_interval           = each.value.checkpoint_interval
        min_pause_between_checkpoints = each.value.min_pause_between_checkpoints
      }

      monitoring_configuration {
        configuration_type = "CUSTOM"
        log_level          = each.value.log_level
        metrics_level      = each.value.metrics_level
      }

      parallelism_configuration {
        configuration_type   = "CUSTOM"
        auto_scaling_enabled = each.value.auto_scaling_enabled
        parallelism          = each.value.parallelism
        parallelism_per_kpu  = each.value.parallelism_per_kpu
      }
    }

    dynamic "environment_properties" {
      for_each = length(each.value.environment_properties) > 0 ? [1] : []
      content {
        property_group {
          property_group_id = "FlinkApplicationProperties"
          property_map      = each.value.environment_properties
        }
      }
    }

    dynamic "vpc_configuration" {
      for_each = length(each.value.vpc_subnet_ids) > 0 ? [1] : []
      content {
        subnet_ids         = each.value.vpc_subnet_ids
        security_group_ids = each.value.vpc_security_group_ids
      }
    }
  }

  dynamic "cloudwatch_logging_options" {
    for_each = each.value.cloudwatch_log_stream_arn != null ? [1] : []
    content {
      log_stream_arn = each.value.cloudwatch_log_stream_arn
    }
  }

  start_application = each.value.start_application

  tags = merge(var.tags, each.value.tags, {
    Name      = "${var.name_prefix}${each.key}"
    ManagedBy = "terraform"
  })
}

# ---------------------------------------------------------------------------
# Flink applications — caller-supplied role
# ---------------------------------------------------------------------------

resource "aws_kinesisanalyticsv2_application" "existing_role" {
  for_each = local.analytics_existing_role

  name                   = "${var.name_prefix}${each.key}"
  runtime_environment    = each.value.runtime_environment
  service_execution_role = each.value.service_execution_role
  description            = each.value.description

  application_configuration {
    application_code_configuration {
      code_content_type = "ZIPFILE"
      code_content {
        s3_content_location {
          bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${each.value.code_s3_bucket}"
          file_key   = each.value.code_s3_key
        }
      }
    }

    flink_application_configuration {
      checkpoint_configuration {
        configuration_type            = "CUSTOM"
        checkpointing_enabled         = each.value.checkpoint_enabled
        checkpoint_interval           = each.value.checkpoint_interval
        min_pause_between_checkpoints = each.value.min_pause_between_checkpoints
      }

      monitoring_configuration {
        configuration_type = "CUSTOM"
        log_level          = each.value.log_level
        metrics_level      = each.value.metrics_level
      }

      parallelism_configuration {
        configuration_type   = "CUSTOM"
        auto_scaling_enabled = each.value.auto_scaling_enabled
        parallelism          = each.value.parallelism
        parallelism_per_kpu  = each.value.parallelism_per_kpu
      }
    }

    dynamic "environment_properties" {
      for_each = length(each.value.environment_properties) > 0 ? [1] : []
      content {
        property_group {
          property_group_id = "FlinkApplicationProperties"
          property_map      = each.value.environment_properties
        }
      }
    }

    dynamic "vpc_configuration" {
      for_each = length(each.value.vpc_subnet_ids) > 0 ? [1] : []
      content {
        subnet_ids         = each.value.vpc_subnet_ids
        security_group_ids = each.value.vpc_security_group_ids
      }
    }
  }

  dynamic "cloudwatch_logging_options" {
    for_each = each.value.cloudwatch_log_stream_arn != null ? [1] : []
    content {
      log_stream_arn = each.value.cloudwatch_log_stream_arn
    }
  }

  start_application = each.value.start_application

  tags = merge(var.tags, each.value.tags, {
    Name      = "${var.name_prefix}${each.key}"
    ManagedBy = "terraform"
  })
}

# ---------------------------------------------------------------------------
# Snapshot resource (enables checkpointed restarts)
# ---------------------------------------------------------------------------

resource "aws_kinesisanalyticsv2_application_snapshot" "auto_role" {
  for_each = {
    for k, v in local.analytics_auto_role : k => v
    if v.checkpoint_enabled
  }

  application_name = aws_kinesisanalyticsv2_application.auto_role[each.key].name
  snapshot_name    = "${var.name_prefix}${each.key}-initial-snapshot"
}

resource "aws_kinesisanalyticsv2_application_snapshot" "existing_role" {
  for_each = {
    for k, v in local.analytics_existing_role : k => v
    if v.checkpoint_enabled
  }

  application_name = aws_kinesisanalyticsv2_application.existing_role[each.key].name
  snapshot_name    = "${var.name_prefix}${each.key}-initial-snapshot"
}
