# unit/validation.tftest.hcl — tf-aws-data-e-athena
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
# Test 1 — workgroup state must be ENABLED or DISABLED
# ---------------------------------------------------------------------------
run "workgroup_state_invalid_value" {
  command = plan

  variables {
    workgroups = {
      "primary" = {
        state = "RUNNING"
        result_configuration = {
          output_location = "s3://my-results-bucket/athena/"
        }
      }
    }
  }

  expect_failures = [
    var.workgroups,
  ]
}

# ---------------------------------------------------------------------------
# Test 2 — workgroup encryption_type must be SSE_S3, SSE_KMS, or CSE_KMS
# ---------------------------------------------------------------------------
run "workgroup_invalid_encryption_type" {
  command = plan

  variables {
    workgroups = {
      "primary" = {
        result_configuration = {
          output_location = "s3://my-results-bucket/athena/"
          encryption_type = "AES256"
        }
      }
    }
  }

  expect_failures = [
    var.workgroups,
  ]
}

# ---------------------------------------------------------------------------
# Test 3 — SSE_KMS encryption requires kms_key_arn on result_configuration
# ---------------------------------------------------------------------------
run "sse_kms_requires_key_arn" {
  command = plan

  variables {
    workgroups = {
      "primary" = {
        result_configuration = {
          output_location = "s3://my-results-bucket/athena/"
          encryption_type = "SSE_KMS"
          kms_key_arn     = null
        }
      }
    }
  }

  expect_failures = [
    var.workgroups,
  ]
}

# ---------------------------------------------------------------------------
# Test 4 — capacity_reservation target_dpus must be positive
# ---------------------------------------------------------------------------
run "capacity_reservation_target_dpus_positive" {
  command = plan

  variables {
    workgroups = {
      "primary" = {
        result_configuration = {
          output_location = "s3://my-results-bucket/athena/"
        }
      }
    }
    capacity_reservations = {
      "res1" = {
        target_dpus = 0
      }
    }
  }

  expect_failures = [
    var.capacity_reservations,
  ]
}
