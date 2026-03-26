# Unit tests — variable validation rules
# command = plan: these tests verify that invalid inputs are rejected

# ──────────────────────────────────────────────────────────────────────────────
# Test 1: visibility_timeout_seconds below minimum (< 0) → expect failure
# ──────────────────────────────────────────────────────────────────────────────
run "invalid_visibility_timeout_below_minimum" {
  command = plan

  # This run block is expected to fail due to validation
  expect_failures = [var.sqs_queues]

  variables {
    name_prefix       = "unit-validation"
    create_sqs_queues = true
    sqs_queues = {
      bad_timeout = {
        visibility_timeout_seconds = -1
        message_retention_seconds  = 86400
      }
    }
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 2: visibility_timeout_seconds above maximum (> 43200) → expect failure
# ──────────────────────────────────────────────────────────────────────────────
run "invalid_visibility_timeout_above_maximum" {
  command = plan

  expect_failures = [var.sqs_queues]

  variables {
    name_prefix       = "unit-validation"
    create_sqs_queues = true
    sqs_queues = {
      bad_timeout = {
        visibility_timeout_seconds = 43201
        message_retention_seconds  = 86400
      }
    }
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 3: visibility_timeout_seconds at exact boundary values → should succeed
# ──────────────────────────────────────────────────────────────────────────────
run "valid_visibility_timeout_at_boundaries" {
  command = plan

  variables {
    name_prefix       = "unit-validation"
    create_sqs_queues = true
    sqs_queues = {
      min_timeout = {
        visibility_timeout_seconds = 0
        message_retention_seconds  = 86400
      }
      max_timeout = {
        visibility_timeout_seconds = 43200
        message_retention_seconds  = 86400
      }
    }
  }

  assert {
    condition     = length(aws_sqs_queue.textract) == 2
    error_message = "Expected 2 SQS queues at boundary visibility_timeout_seconds values (0 and 43200)."
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 4: message_retention_seconds below minimum (< 60) → expect failure
# ──────────────────────────────────────────────────────────────────────────────
run "invalid_message_retention_below_minimum" {
  command = plan

  expect_failures = [var.sqs_queues]

  variables {
    name_prefix       = "unit-validation"
    create_sqs_queues = true
    sqs_queues = {
      bad_retention = {
        visibility_timeout_seconds = 300
        message_retention_seconds  = 59
      }
    }
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 5: message_retention_seconds above maximum (> 1209600 = 14 days) → expect failure
# ──────────────────────────────────────────────────────────────────────────────
run "invalid_message_retention_above_maximum" {
  command = plan

  expect_failures = [var.sqs_queues]

  variables {
    name_prefix       = "unit-validation"
    create_sqs_queues = true
    sqs_queues = {
      bad_retention = {
        visibility_timeout_seconds = 300
        message_retention_seconds  = 1209601
      }
    }
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 6: message_retention_seconds at exact boundary values → should succeed
# ──────────────────────────────────────────────────────────────────────────────
run "valid_message_retention_at_boundaries" {
  command = plan

  variables {
    name_prefix       = "unit-validation"
    create_sqs_queues = true
    sqs_queues = {
      min_retention = {
        visibility_timeout_seconds = 300
        message_retention_seconds  = 60
      }
      max_retention = {
        visibility_timeout_seconds = 300
        message_retention_seconds  = 1209600
      }
    }
  }

  assert {
    condition     = length(aws_sqs_queue.textract) == 2
    error_message = "Expected 2 SQS queues at boundary message_retention_seconds values (60 and 1209600)."
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 7: Multiple queues — one valid, one invalid → entire map rejected
# ──────────────────────────────────────────────────────────────────────────────
run "mixed_valid_invalid_queues_rejected" {
  command = plan

  expect_failures = [var.sqs_queues]

  variables {
    name_prefix       = "unit-validation"
    create_sqs_queues = true
    sqs_queues = {
      valid_queue = {
        visibility_timeout_seconds = 300
        message_retention_seconds  = 86400
      }
      invalid_queue = {
        visibility_timeout_seconds = 99999 # invalid
        message_retention_seconds  = 86400
      }
    }
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 8: Valid defaults (optional fields omitted) → should succeed using defaults
# ──────────────────────────────────────────────────────────────────────────────
run "valid_queue_with_all_defaults" {
  command = plan

  variables {
    name_prefix       = "unit-validation"
    create_sqs_queues = true
    sqs_queues = {
      # All fields optional; defaults: visibility=300, retention=86400
      default_queue = {}
    }
  }

  assert {
    condition     = length(aws_sqs_queue.textract) == 1
    error_message = "Expected 1 SQS queue when using all default queue configuration values."
  }
}
