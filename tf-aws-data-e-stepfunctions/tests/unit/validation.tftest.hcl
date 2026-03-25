# tests/unit/validation.tftest.hcl
# Verifies that an invalid state machine type is rejected by module validation.
# Valid values are STANDARD and EXPRESS only.

run "invalid_state_machine_type_rejected" {
  command = plan

  variables {
    create_activities = false
    create_alarms     = false
    create_iam_role   = false
    role_arn          = "arn:aws:iam::123456789012:role/test"

    state_machines = {
      bad_type = {
        # INVALID type — must be STANDARD or EXPRESS.
        type       = "INVALID_TYPE"
        definition = "{\"Comment\":\"Test\",\"StartAt\":\"Pass\",\"States\":{\"Pass\":{\"Type\":\"Pass\",\"End\":true}}}"
      }
    }
  }

  module {
    source = "../../"
  }

  # Expect the plan to fail due to invalid state machine type.
  expect_failures = [
    var.state_machines,
  ]
}
