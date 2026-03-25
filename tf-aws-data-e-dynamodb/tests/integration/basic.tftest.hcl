# Integration test — tf-aws-data-e-dynamodb
# DynamoDB PAY_PER_REQUEST is free at low usage.
# Uses command = apply: on-demand tables have no standing cost.

run "dynamodb_table_apply" {
  # SKIP_IN_CI
  # Cost: DynamoDB on-demand ~free at test volumes
  command = apply

  variables {
    name_prefix = "inttest"

    tables = {
      basic = {
        billing_mode        = "PAY_PER_REQUEST"
        hash_key            = "id"
        hash_key_type       = "S"
        deletion_protection = false
        point_in_time_recovery = false
        backup_enabled      = false
        tags = {
          Environment = "integration-test"
        }
      }
    }

    create_alarms     = false
    create_backup_plan = false
    create_iam_roles  = false

    tags = {
      Environment = "integration-test"
      ManagedBy   = "terraform-test"
    }
  }

  assert {
    condition     = length(output.table_arns) == 1
    error_message = "Expected exactly one table ARN."
  }

  assert {
    condition     = output.table_arns["basic"] != null && output.table_arns["basic"] != ""
    error_message = "table_arns[\"basic\"] must be a non-empty ARN."
  }

  assert {
    condition     = output.table_names["basic"] != null && output.table_names["basic"] != ""
    error_message = "table_names[\"basic\"] must be a non-empty string."
  }

  assert {
    condition     = output.table_ids["basic"] != null && output.table_ids["basic"] != ""
    error_message = "table_ids[\"basic\"] must be a non-empty string."
  }
}
