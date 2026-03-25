# Unit tests — variable validation for tf-aws-s3
# command = plan; no real AWS resources are created.

run "valid_sse_algorithm_aes256" {
  command = plan

  variables {
    bucket_name   = "my-test-bucket-aes256-12345"
    sse_algorithm = "AES256"
  }

  assert {
    condition     = var.sse_algorithm == "AES256"
    error_message = "sse_algorithm 'AES256' should be accepted."
  }
}

run "valid_sse_algorithm_kms" {
  command = plan

  variables {
    bucket_name   = "my-test-bucket-kms-12345"
    sse_algorithm = "aws:kms"
  }

  assert {
    condition     = var.sse_algorithm == "aws:kms"
    error_message = "sse_algorithm 'aws:kms' should be accepted."
  }
}

run "valid_sse_algorithm_dsse_kms" {
  command = plan

  variables {
    bucket_name   = "my-test-bucket-dsse-12345"
    sse_algorithm = "aws:kms:dsse"
  }

  assert {
    condition     = var.sse_algorithm == "aws:kms:dsse"
    error_message = "sse_algorithm 'aws:kms:dsse' should be accepted."
  }
}

# Negative test: invalid sse_algorithm must be rejected.
run "invalid_sse_algorithm_rejected" {
  command = plan

  variables {
    bucket_name   = "my-test-bucket-bad-sse-12345"
    sse_algorithm = "NONE"
  }

  expect_failures = [
    var.sse_algorithm,
  ]
}

# Verify lifecycle rule with a valid transition is accepted.
run "valid_lifecycle_rule_transition" {
  command = plan

  variables {
    bucket_name = "my-test-bucket-lifecycle-12345"
    lifecycle_rules = [
      {
        id      = "archive-old-objects"
        enabled = true
        transition = [
          {
            days          = 90
            storage_class = "STANDARD_IA"
          }
        ]
      }
    ]
  }

  assert {
    condition     = length(var.lifecycle_rules) == 1
    error_message = "Expected 1 lifecycle rule to be configured."
  }

  assert {
    condition     = var.lifecycle_rules[0].transition[0].days == 90
    error_message = "Expected transition days to be 90."
  }
}
