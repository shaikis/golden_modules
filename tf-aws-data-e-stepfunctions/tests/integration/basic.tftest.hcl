# tests/integration/basic.tftest.hcl
# SKIP_IN_CI
# Creates a real Step Functions state machine (free tier for STANDARD type)
# using a minimal Pass-state ASL definition, then asserts the ARN output.
# Requires valid AWS credentials and IAM permissions for states:CreateStateMachine.

run "create_state_machine_and_assert_arn" {
  command = apply

  variables {
    create_activities = false
    create_alarms     = false
    create_iam_role   = false
    role_arn          = "arn:aws:iam::123456789012:role/test"

    state_machines = {
      test_pass = {
        type       = "STANDARD"
        definition = "{\"Comment\":\"Test\",\"StartAt\":\"Pass\",\"States\":{\"Pass\":{\"Type\":\"Pass\",\"End\":true}}}"
        role_arn   = "arn:aws:iam::123456789012:role/test"

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

  # Assert that a state machine ARN was produced in module outputs.
  assert {
    condition     = length(keys(module.state_machine_arns)) > 0
    error_message = "Expected at least one state machine ARN in module outputs but got none."
  }
}
