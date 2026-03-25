# Unit tests — tf-aws-kinesis variable validation
# command = plan: no real AWS resources are created.

run "valid_retention_period_24h_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    kinesis_streams = {
      my_stream = {
        shard_count      = 1
        retention_period = 24
      }
    }
  }

  assert {
    condition     = var.kinesis_streams["my_stream"].retention_period == 24
    error_message = "Expected retention_period = 24 to be accepted."
  }
}

run "valid_retention_period_168h_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    kinesis_streams = {
      my_stream = {
        shard_count      = 1
        retention_period = 168
      }
    }
  }

  assert {
    condition     = var.kinesis_streams["my_stream"].retention_period == 168
    error_message = "Expected retention_period = 168 to be accepted."
  }
}

run "stream_on_demand_mode" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    kinesis_streams = {
      on_demand_stream = {
        on_demand   = true
        shard_count = null
      }
    }
  }

  assert {
    condition     = var.kinesis_streams["on_demand_stream"].on_demand == true
    error_message = "Expected on_demand = true to be accepted."
  }
}

run "stream_defaults_kms_encryption" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    kinesis_streams = {
      encrypted_stream = {
        shard_count = 1
      }
    }
  }

  assert {
    condition     = var.kinesis_streams["encrypted_stream"].encryption_type == "KMS"
    error_message = "Expected encryption_type to default to KMS."
  }

  assert {
    condition     = var.kinesis_streams["encrypted_stream"].kms_key_id == "alias/aws/kinesis"
    error_message = "Expected kms_key_id to default to alias/aws/kinesis."
  }
}

run "create_alarms_false_without_sns_topic" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    create_alarms      = false
    alarm_sns_topic_arn = null
  }

  # Alarms disabled without an SNS topic — should plan cleanly.
  assert {
    condition     = var.create_alarms == false
    error_message = "Expected create_alarms=false with no SNS topic to be valid."
  }
}
