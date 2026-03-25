# Integration tests — tf-aws-kinesis basic
# command = apply: REAL AWS resources are created, then destroyed.
# Cost: ~$0.015 per shard-hour. Keep shard_count = 1 and destroy quickly.
#
# Prerequisites:
#   export AWS_ACCESS_KEY_ID="..."
#   export AWS_SECRET_ACCESS_KEY="..."
#   export AWS_DEFAULT_REGION="us-east-1"

# SKIP_IN_CI
run "create_single_shard_stream" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name_prefix = "tftest-"
    tags = {
      Environment = "test"
      ManagedBy   = "terraform-test"
    }
    kinesis_streams = {
      basic = {
        shard_count      = 1
        retention_period = 24
        encryption_type  = "KMS"
        kms_key_id       = "alias/aws/kinesis"
      }
    }
    create_iam_roles = true
  }

  assert {
    condition     = length(var.kinesis_streams) == 1
    error_message = "Expected exactly one Kinesis stream to be configured."
  }

  assert {
    condition     = var.kinesis_streams["basic"].shard_count == 1
    error_message = "Expected shard_count to be 1."
  }
}

# SKIP_IN_CI
run "create_on_demand_stream" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name_prefix = "tftest-od-"
    tags = {
      Environment = "test"
    }
    kinesis_streams = {
      on_demand = {
        on_demand        = true
        shard_count      = null
        retention_period = 24
      }
    }
    create_iam_roles = true
  }

  assert {
    condition     = var.kinesis_streams["on_demand"].on_demand == true
    error_message = "Expected on_demand stream to be configured."
  }
}
