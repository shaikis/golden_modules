# unit/validation.tftest.hcl — tf-aws-data-e-dynamodb
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
# Test 1 — billing_mode must be PAY_PER_REQUEST or PROVISIONED
# ---------------------------------------------------------------------------
run "table_billing_mode_invalid_value" {
  command = plan

  variables {
    tables = {
      "orders" = {
        hash_key     = "id"
        billing_mode = "FIXED"
      }
    }
    create_alarms     = false
    create_backup_plan = false
  }

  expect_failures = [
    var.tables,
  ]
}

# ---------------------------------------------------------------------------
# Test 2 — PROVISIONED billing mode requires read_capacity and write_capacity
# ---------------------------------------------------------------------------
run "provisioned_billing_requires_capacity_units" {
  command = plan

  variables {
    tables = {
      "orders" = {
        hash_key       = "id"
        billing_mode   = "PROVISIONED"
        read_capacity  = null
        write_capacity = null
      }
    }
    create_alarms     = false
    create_backup_plan = false
  }

  expect_failures = [
    var.tables,
  ]
}

# ---------------------------------------------------------------------------
# Test 3 — hash_key_type must be S, N, or B
# ---------------------------------------------------------------------------
run "hash_key_type_invalid_value" {
  command = plan

  variables {
    tables = {
      "orders" = {
        hash_key      = "id"
        hash_key_type = "X"
      }
    }
    create_alarms     = false
    create_backup_plan = false
  }

  expect_failures = [
    var.tables,
  ]
}

# ---------------------------------------------------------------------------
# Test 4 — table_class must be STANDARD or STANDARD_INFREQUENT_ACCESS
# ---------------------------------------------------------------------------
run "table_class_invalid_value" {
  command = plan

  variables {
    tables = {
      "orders" = {
        hash_key    = "id"
        table_class = "GLACIER"
      }
    }
    create_alarms     = false
    create_backup_plan = false
  }

  expect_failures = [
    var.tables,
  ]
}

# ---------------------------------------------------------------------------
# Test 5 — create_alarms = true without alarm_sns_topic_arn
# ---------------------------------------------------------------------------
run "alarms_require_sns_topic" {
  command = plan

  variables {
    tables = {
      "orders" = {
        hash_key = "id"
      }
    }
    create_alarms       = true
    alarm_sns_topic_arn = null
    create_backup_plan  = false
  }

  expect_failures = [
    var.alarm_sns_topic_arn,
  ]
}
