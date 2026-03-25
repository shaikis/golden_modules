# unit/defaults.tftest.hcl — tf-aws-data-e-kinesis
# plan-only: verifies feature-gate defaults and BYO IAM pattern
# No AWS credentials required; runs entirely as a plan.

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# ---------------------------------------------------------------------------
# Test 1 — minimal config: only a Kinesis stream is planned
# ---------------------------------------------------------------------------
run "minimal_config_plans_only_stream" {
  command = plan

  variables {
    kinesis_streams = {
      "events" = { shard_count = 1 }
    }
  }

  # Core stream must be planned
  assert {
    condition     = length(aws_kinesis_stream.this) == 1
    error_message = "Expected exactly one Kinesis stream to be planned."
  }

  # Firehose gate is false by default — no firehose resources
  assert {
    condition     = length(aws_kinesis_firehose_delivery_stream.this) == 0
    error_message = "create_firehose_streams defaults to false; no firehose should be planned."
  }

  # Analytics gate is false by default
  assert {
    condition     = length(aws_kinesisanalyticsv2_application.this) == 0
    error_message = "create_analytics_applications defaults to false; no analytics app should be planned."
  }

  # Stream consumers gate is false by default
  assert {
    condition     = length(aws_kinesis_stream_consumer.this) == 0
    error_message = "create_stream_consumers defaults to false; no consumers should be planned."
  }

  # Alarms gate is false by default
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 0
    error_message = "create_alarms defaults to false; no alarms should be planned."
  }
}

# ---------------------------------------------------------------------------
# Test 2 — BYO IAM: providing role ARNs suppresses auto-create IAM resources
# ---------------------------------------------------------------------------
run "byo_iam_suppresses_role_creation" {
  command = plan

  variables {
    kinesis_streams = {
      "events" = { shard_count = 1 }
    }
    create_producer_role = false
    create_consumer_role = false
    create_firehose_role = false
  }

  assert {
    condition     = length(aws_iam_role.producer) == 0
    error_message = "create_producer_role = false should suppress producer IAM role creation."
  }

  assert {
    condition     = length(aws_iam_role.consumer) == 0
    error_message = "create_consumer_role = false should suppress consumer IAM role creation."
  }
}

# ---------------------------------------------------------------------------
# Test 3 — gates remain false without explicit opt-in
# ---------------------------------------------------------------------------
run "all_feature_gates_default_false" {
  command = plan

  variables {
    kinesis_streams = {
      "events" = { shard_count = 1 }
    }
    tags = { Environment = "test" }
  }

  assert {
    condition     = length(aws_kinesis_firehose_delivery_stream.this) == 0
    error_message = "Firehose gate must be false by default."
  }

  assert {
    condition     = length(aws_kinesisanalyticsv2_application.this) == 0
    error_message = "Analytics gate must be false by default."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 0
    error_message = "Alarms gate must be false by default."
  }
}

# ---------------------------------------------------------------------------
# Test 4 — tag propagation
# ---------------------------------------------------------------------------
run "tags_propagate_to_stream" {
  command = plan

  variables {
    kinesis_streams = {
      "events" = { shard_count = 1 }
    }
    tags = { Environment = "test", Team = "data-engineering" }
  }

  assert {
    condition     = aws_kinesis_stream.this["events"].tags["Environment"] == "test"
    error_message = "Environment tag must propagate to the Kinesis stream."
  }
}
