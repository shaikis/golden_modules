# ---------------------------------------------------------------------------
# Unit test: input validation
#
# Every run block here is expected to FAIL with a specific error.
# Terraform test uses `expect_failures` to assert that a validation block
# fires — the test passes only when the expected failure occurs.
#
# command = plan  →  no AWS credentials required
# ---------------------------------------------------------------------------

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { name = "us-east-1" }
  }
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
      user_id    = "AIDAAAAAAAAAAAAAAAAAA"
    }
  }
  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
}

# ---------------------------------------------------------------------------
# Validation 1: role_arn must be a valid IAM role ARN
# ---------------------------------------------------------------------------
run "invalid_role_arn_rejected" {
  command = plan

  variables {
    create_iam_role = false
    role_arn        = "not-a-valid-arn"
  }

  expect_failures = [var.role_arn]
}

# ---------------------------------------------------------------------------
# Validation 2: kms_key_arn must be a valid KMS key ARN
# ---------------------------------------------------------------------------
run "invalid_kms_key_arn_rejected" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:s3:::my-bucket"   # wrong service
  }

  expect_failures = [var.kms_key_arn]
}

# ---------------------------------------------------------------------------
# Validation 3: name_prefix max length = 32
# ---------------------------------------------------------------------------
run "name_prefix_too_long_rejected" {
  command = plan

  variables {
    # 33 characters — one over the limit
    name_prefix = "this-prefix-is-way-too-long-for-m"
  }

  expect_failures = [var.name_prefix]
}

# ---------------------------------------------------------------------------
# Validation 4: alarm_sns_arns must contain valid SNS ARNs
# ---------------------------------------------------------------------------
run "invalid_sns_arn_in_alarm_list_rejected" {
  command = plan

  variables {
    create_alarms  = true
    alarm_sns_arns = ["arn:aws:sqs:us-east-1:123456789012:my-queue"]   # SQS, not SNS
  }

  expect_failures = [var.alarm_sns_arns]
}

# ---------------------------------------------------------------------------
# Validation 5: alarm_period_seconds must be an allowed value
# ---------------------------------------------------------------------------
run "invalid_alarm_period_rejected" {
  command = plan

  variables {
    alarm_period_seconds = 45   # not in [10, 30, 60, 300, 600, 900, 3600]
  }

  expect_failures = [var.alarm_period_seconds]
}

# ---------------------------------------------------------------------------
# Validation 6: alarm_error_threshold must be >= 1
# ---------------------------------------------------------------------------
run "alarm_threshold_zero_rejected" {
  command = plan

  variables {
    alarm_error_threshold = 0
  }

  expect_failures = [var.alarm_error_threshold]
}

# ---------------------------------------------------------------------------
# Validation 7: stream processor cannot have both face_search and
#               connected_home_labels set simultaneously
# ---------------------------------------------------------------------------
run "stream_processor_dual_settings_rejected" {
  command = plan

  variables {
    create_stream_processors = true
    stream_processors = {
      "bad-processor" = {
        kinesis_video_stream_arn = "arn:aws:kinesisvideo:us-east-1:123456789012:stream/cam/0"
        kinesis_data_stream_arn  = "arn:aws:kinesis:us-east-1:123456789012:stream/out"
        face_search = {
          collection_id        = "my-collection"
          face_match_threshold = 80
        }
        connected_home_labels = ["PERSON", "PET"]
      }
    }
  }

  expect_failures = [var.stream_processors]
}

# ---------------------------------------------------------------------------
# Validation 8: alarm_evaluation_periods must be >= 1
# ---------------------------------------------------------------------------
run "alarm_evaluation_periods_zero_rejected" {
  command = plan

  variables {
    alarm_evaluation_periods = 0
  }

  expect_failures = [var.alarm_evaluation_periods]
}
