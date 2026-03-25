# unit/validation.tftest.hcl — tf-aws-data-e-kinesis
# plan-only: verifies variable validation rules reject invalid inputs.
# Each run block expects an error (expect_failures).

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# ---------------------------------------------------------------------------
# Test 1 — create_alarms = true without alarm_sns_topic_arn should fail
#           (guards the dependency between the alarm gate and its SNS target)
# ---------------------------------------------------------------------------
run "alarms_require_sns_topic_arn" {
  command = plan

  variables {
    kinesis_streams = {
      "events" = { shard_count = 1 }
    }
    create_alarms       = true
    alarm_sns_topic_arn = null
  }

  expect_failures = [
    var.alarm_sns_topic_arn,
  ]
}

# ---------------------------------------------------------------------------
# Test 2 — iterator_age_threshold_ms must be positive
# ---------------------------------------------------------------------------
run "iterator_age_threshold_must_be_positive" {
  command = plan

  variables {
    kinesis_streams = {
      "events" = { shard_count = 1 }
    }
    iterator_age_threshold_ms = -1
  }

  expect_failures = [
    var.iterator_age_threshold_ms,
  ]
}

# ---------------------------------------------------------------------------
# Test 3 — firehose_success_threshold must be between 0 and 1
# ---------------------------------------------------------------------------
run "firehose_success_threshold_out_of_range" {
  command = plan

  variables {
    kinesis_streams = {
      "events" = { shard_count = 1 }
    }
    firehose_success_threshold = 1.5
  }

  expect_failures = [
    var.firehose_success_threshold,
  ]
}

# ---------------------------------------------------------------------------
# Test 4 — alarm_period_seconds must be positive
# ---------------------------------------------------------------------------
run "alarm_period_must_be_positive" {
  command = plan

  variables {
    kinesis_streams = {
      "events" = { shard_count = 1 }
    }
    alarm_period_seconds = 0
  }

  expect_failures = [
    var.alarm_period_seconds,
  ]
}
