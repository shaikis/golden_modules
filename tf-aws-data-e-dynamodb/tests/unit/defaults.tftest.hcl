# unit/defaults.tftest.hcl — tf-aws-data-e-dynamodb
# plan-only: verifies feature-gate defaults and BYO KMS pattern
# No AWS credentials required; runs entirely as a plan.

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# ---------------------------------------------------------------------------
# Test 1 — minimal config: only the DynamoDB table is planned
# ---------------------------------------------------------------------------
run "minimal_config_plans_only_table" {
  command = plan

  variables {
    tables = {
      "orders" = {
        hash_key = "id"
      }
    }
    # Disable defaulting-true gates so we exercise the true minimum
    create_alarms     = false
    create_backup_plan = false
  }

  # Core table must be planned
  assert {
    condition     = length(aws_dynamodb_table.this) == 1
    error_message = "Expected exactly one DynamoDB table to be planned."
  }

  # Global tables map defaults to empty
  assert {
    condition     = length(aws_dynamodb_global_table.this) == 0
    error_message = "global_tables defaults to empty; no global table resources should be planned."
  }

  # No CloudWatch alarms when gate is false
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 0
    error_message = "create_alarms = false must not plan CloudWatch alarms."
  }
}

# ---------------------------------------------------------------------------
# Test 2 — create_alarms defaults to true, requires SNS topic
# ---------------------------------------------------------------------------
run "alarms_gate_defaults_true" {
  command = plan

  variables {
    tables = {
      "orders" = {
        hash_key = "id"
      }
    }
    alarm_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:alerts"
    create_backup_plan  = false
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) > 0
    error_message = "create_alarms defaults to true; alarms should be planned when SNS topic is provided."
  }
}

# ---------------------------------------------------------------------------
# Test 3 — BYO KMS key: table uses provided ARN, no aws_kms_key created
# ---------------------------------------------------------------------------
run "byo_kms_key_used_for_table_encryption" {
  command = plan

  variables {
    tables = {
      "orders" = {
        hash_key    = "id"
        kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abc123"
      }
    }
    create_alarms     = false
    create_backup_plan = false
  }

  assert {
    condition     = length(aws_kms_key.this) == 0
    error_message = "When kms_key_arn is provided on the table, the module must not create a KMS key."
  }

  assert {
    condition     = aws_dynamodb_table.this["orders"].server_side_encryption[0].kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/abc123"
    error_message = "The BYO KMS key ARN must be used for table encryption."
  }
}

# ---------------------------------------------------------------------------
# Test 4 — IAM roles gate
# ---------------------------------------------------------------------------
run "byo_iam_suppresses_role_creation" {
  command = plan

  variables {
    tables = {
      "orders" = {
        hash_key = "id"
      }
    }
    create_iam_roles  = false
    create_alarms     = false
    create_backup_plan = false
  }

  assert {
    condition     = length(aws_iam_role.this) == 0
    error_message = "create_iam_roles = false should suppress IAM role creation."
  }
}

# ---------------------------------------------------------------------------
# Test 5 — tag propagation
# ---------------------------------------------------------------------------
run "tags_propagate_to_table" {
  command = plan

  variables {
    tables = {
      "orders" = {
        hash_key = "id"
      }
    }
    create_alarms     = false
    create_backup_plan = false
    tags              = { Environment = "test", Team = "data-engineering" }
  }

  assert {
    condition     = aws_dynamodb_table.this["orders"].tags["Environment"] == "test"
    error_message = "Environment tag must propagate to the DynamoDB table."
  }
}
