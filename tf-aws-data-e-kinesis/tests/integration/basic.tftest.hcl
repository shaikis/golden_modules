# Integration test — tf-aws-data-e-kinesis
# Kinesis costs $0.015/shard-hour. Stream is destroyed immediately after test.
# Uses command = apply: stream is created then torn down, minimal cost incurred.

run "kinesis_stream_apply" {
  # SKIP_IN_CI
  # Cost: ~$0.015/shard-hour. Destroyed immediately after test completes.
  command = apply

  variables {
    name_prefix = "inttest"

    kinesis_streams = {
      basic = {
        shard_count      = 1
        on_demand        = false
        retention_period = 24
        encryption_type  = "NONE"
        kms_key_id       = null
        shard_level_metrics = []
        enforce_consumer_deletion = false
        tags = {
          Environment = "integration-test"
        }
      }
    }

    create_firehose_streams        = false
    create_analytics_applications  = false
    create_stream_consumers        = false
    create_alarms                  = false
    create_iam_roles               = false
    create_producer_role           = false
    create_consumer_role           = false
    create_firehose_role           = false

    tags = {
      Environment = "integration-test"
      ManagedBy   = "terraform-test"
    }
  }

  assert {
    condition     = length(output.stream_arns) == 1
    error_message = "Expected exactly one stream ARN."
  }

  assert {
    condition     = output.stream_arns["basic"] != null && output.stream_arns["basic"] != ""
    error_message = "stream_arns[\"basic\"] must be a non-empty ARN."
  }

  assert {
    condition     = output.stream_names["basic"] != null && output.stream_names["basic"] != ""
    error_message = "stream_names[\"basic\"] must be a non-empty string."
  }

  assert {
    condition     = output.stream_ids["basic"] != null && output.stream_ids["basic"] != ""
    error_message = "stream_ids[\"basic\"] must be a non-empty string."
  }

  assert {
    condition     = output.stream_shard_counts["basic"] == 1
    error_message = "stream_shard_counts[\"basic\"] must be 1."
  }
}
