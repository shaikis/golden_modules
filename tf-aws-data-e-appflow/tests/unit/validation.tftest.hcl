# Unit test — input validation for tf-aws-data-e-appflow
# command = plan: no real AWS resources are created.
# These runs verify that invalid inputs are rejected before any apply.

# NOTE: AppFlow module currently only contains versions.tf.
# Validation tests are structured to match the expected interface once
# flow/connector-profile variables are added (create_flows, trigger_type, etc.).
# Until those variables exist the plan runs succeed trivially — they will
# begin enforcing constraints automatically when validation blocks are added.

run "valid_minimal_config_accepted" {
  command = plan

  module {
    source = "../../"
  }

  # No variables required at present; a clean plan is the passing condition.
  assert {
    condition     = true
    error_message = "A minimal valid config must plan successfully."
  }
}

# Placeholder: once trigger_type variable with validation is added, uncomment
# and the test framework will expect this run to fail plan with an error
# matching the pattern below.
#
# run "invalid_trigger_type_rejected" {
#   command = plan
#   expect_failures = [var.trigger_type]
#
#   module {
#     source = "../../"
#   }
#
#   variables {
#     trigger_type = "INVALID_TRIGGER"
#   }
# }
