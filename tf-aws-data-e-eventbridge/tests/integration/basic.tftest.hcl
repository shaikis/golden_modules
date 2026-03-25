# tests/integration/basic.tftest.hcl
# SKIP_IN_CI
# Creates a real custom EventBridge bus (free tier) and asserts the bus ARN output.
# Requires valid AWS credentials and sufficient IAM permissions.

run "create_custom_bus_and_assert_arn" {
  command = apply

  variables {
    create_custom_buses      = true
    create_api_connections   = false
    create_api_destinations  = false
    create_archives          = false
    create_pipes             = false
    create_schema_registries = false
    create_alarms            = false
    create_iam_role          = false
    role_arn                 = "arn:aws:iam::123456789012:role/test"

    event_buses = {
      test_bus = {
        tags = {
          Environment = "test"
          ManagedBy   = "terraform-test"
        }
      }
    }

    tags = {
      Environment = "test"
      ManagedBy   = "terraform-test"
    }
  }

  module {
    source = "../../"
  }

  # Assert that at least one bus ARN was produced in the outputs.
  assert {
    condition     = length(keys(module.bus_arns)) > 0
    error_message = "Expected at least one bus ARN in module outputs but got none."
  }
}
