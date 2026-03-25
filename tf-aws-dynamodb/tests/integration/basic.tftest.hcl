# Integration test — tf-aws-dynamodb basic
# command = apply (creates real AWS resources — costs money)
# Prerequisites: AWS credentials with DynamoDB permissions

provider "aws" {
  region = "us-east-1"
}

variables {
  name_prefix        = "tftest"
  create_backup_plan = false
  create_alarms      = false
  create_iam_roles   = false
  tables = {
    test_orders = {
      hash_key            = "order_id"
      billing_mode        = "PAY_PER_REQUEST"
      deletion_protection = false
    }
  }
}

# SKIP_IN_CI
run "basic_dynamodb_table" {
  command = apply

  module {
    source = "../../"
  }

  assert {
    condition     = length(output.table_arns) > 0
    error_message = "At least one table ARN should be present after apply."
  }

  assert {
    condition     = length(output.table_names) > 0
    error_message = "At least one table name should be present after apply."
  }
}
