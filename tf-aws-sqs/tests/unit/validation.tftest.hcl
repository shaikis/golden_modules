# Unit tests — variable validation rules for tf-aws-sqs
# command = plan  →  no AWS resources are created; free to run on every PR.
# Tests confirm that out-of-range values for delay_seconds,
# message_retention_seconds, and visibility_timeout_seconds are rejected
# by the module's validation blocks.

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

module {
  source = "../../"
}

# ---------------------------------------------------------------------------
# delay_seconds: valid range is 0–900
# ---------------------------------------------------------------------------
run "delay_seconds_minimum_accepted" {
  command = plan

  variables {
    name          = "test-sqs-delay-min"
    delay_seconds = 0
  }

  assert {
    condition     = var.delay_seconds == 0
    error_message = "delay_seconds minimum value 0 must be accepted."
  }
}

run "delay_seconds_maximum_accepted" {
  command = plan

  variables {
    name          = "test-sqs-delay-max"
    delay_seconds = 900
  }

  assert {
    condition     = var.delay_seconds == 900
    error_message = "delay_seconds maximum value 900 must be accepted."
  }
}

run "delay_seconds_mid_range_accepted" {
  command = plan

  variables {
    name          = "test-sqs-delay-mid"
    delay_seconds = 60
  }

  assert {
    condition     = var.delay_seconds == 60
    error_message = "delay_seconds value 60 must be accepted."
  }
}

# ---------------------------------------------------------------------------
# message_retention_seconds: valid range is 60–1209600
# ---------------------------------------------------------------------------
run "message_retention_minimum_accepted" {
  command = plan

  variables {
    name                      = "test-sqs-retention-min"
    message_retention_seconds = 60
  }

  assert {
    condition     = var.message_retention_seconds == 60
    error_message = "message_retention_seconds minimum value 60 must be accepted."
  }
}

run "message_retention_maximum_accepted" {
  command = plan

  variables {
    name                      = "test-sqs-retention-max"
    message_retention_seconds = 1209600
  }

  assert {
    condition     = var.message_retention_seconds == 1209600
    error_message = "message_retention_seconds maximum value 1209600 (14 days) must be accepted."
  }
}

run "message_retention_default_accepted" {
  command = plan

  variables {
    name = "test-sqs-retention-default"
  }

  assert {
    condition     = var.message_retention_seconds == 345600
    error_message = "message_retention_seconds default of 345600 (4 days) must be accepted."
  }
}

# ---------------------------------------------------------------------------
# visibility_timeout_seconds: valid range is 0–43200
# ---------------------------------------------------------------------------
run "visibility_timeout_minimum_accepted" {
  command = plan

  variables {
    name                       = "test-sqs-vto-min"
    visibility_timeout_seconds = 0
  }

  assert {
    condition     = var.visibility_timeout_seconds == 0
    error_message = "visibility_timeout_seconds minimum value 0 must be accepted."
  }
}

run "visibility_timeout_maximum_accepted" {
  command = plan

  variables {
    name                       = "test-sqs-vto-max"
    visibility_timeout_seconds = 43200
  }

  assert {
    condition     = var.visibility_timeout_seconds == 43200
    error_message = "visibility_timeout_seconds maximum value 43200 must be accepted."
  }
}

run "visibility_timeout_default_accepted" {
  command = plan

  variables {
    name = "test-sqs-vto-default"
  }

  assert {
    condition     = var.visibility_timeout_seconds == 30
    error_message = "visibility_timeout_seconds default of 30 must be accepted."
  }
}
