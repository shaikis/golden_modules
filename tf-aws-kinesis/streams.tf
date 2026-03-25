# ---------------------------------------------------------------------------
# Kinesis Data Streams
# ---------------------------------------------------------------------------
# LIFECYCLE NOTE: Changing stream_mode between ON_DEMAND and PROVISIONED
# or modifying encryption_type causes in-place updates. Changing the
# stream name forces replacement and destroys all data. Use lifecycle
# prevent_destroy in production environments.
# ---------------------------------------------------------------------------

locals {
  # Determine stream mode per stream definition
  streams_with_mode = {
    for k, v in var.kinesis_streams : k => merge(v, {
      mode = (v.on_demand == true || v.shard_count == null) ? "ON_DEMAND" : "PROVISIONED"
    })
  }
}

resource "aws_kinesis_stream" "this" {
  for_each = local.streams_with_mode

  name             = "${var.name_prefix}${each.key}"
  retention_period = each.value.retention_period

  # Shard count only applies to PROVISIONED mode
  shard_count = each.value.mode == "PROVISIONED" ? each.value.shard_count : null

  shard_level_metrics = each.value.shard_level_metrics

  stream_mode_details {
    stream_mode = each.value.mode
  }

  encryption_type           = each.value.encryption_type
  kms_key_id                = each.value.encryption_type == "KMS" ? each.value.kms_key_id : null
  enforce_consumer_deletion = each.value.enforce_consumer_deletion

  tags = merge(var.tags, each.value.tags, {
    Name      = "${var.name_prefix}${each.key}"
    ManagedBy = "terraform"
  })

  # LIFECYCLE: prevent accidental stream deletion/recreation in production.
  # Uncomment the block below for production workloads:
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# ---------------------------------------------------------------------------
# Enhanced Fan-Out Consumers
# ---------------------------------------------------------------------------

resource "aws_kinesis_stream_consumer" "this" {
  for_each = var.create_stream_consumers ? var.stream_consumers : {}

  name       = coalesce(each.value.consumer_name, "${var.name_prefix}${each.key}")
  stream_arn = aws_kinesis_stream.this[each.value.stream_key].arn
}
