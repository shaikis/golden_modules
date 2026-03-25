# tests/unit/validation.tftest.hcl
# Verifies that AWS-reserved bus name prefixes are rejected by module validation.
# EventBridge does not allow custom buses whose names begin with "aws.".

run "invalid_bus_name_aws_prefix_rejected" {
  command = plan

  variables {
    create_custom_buses = true
    create_iam_role     = false
    role_arn            = "arn:aws:iam::123456789012:role/test"

    event_buses = {
      reserved = {
        # AWS reserved prefix — must be rejected by the module's validation rule.
        event_source_name = "aws.partner/invalid-reserved-name"
      }
    }
  }

  module {
    source = "../../"
  }

  # Expect the plan to fail because the bus name uses an AWS-reserved prefix.
  expect_failures = [
    var.event_buses,
  ]
}
