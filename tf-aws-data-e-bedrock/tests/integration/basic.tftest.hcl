# Integration test — basic guardrail creation for tf-aws-data-e-bedrock
# command = apply: creates a real Bedrock Guardrail in AWS.
# SKIP_IN_CI

# Prerequisites:
#   export AWS_ACCESS_KEY_ID="..."
#   export AWS_SECRET_ACCESS_KEY="..."
#   export AWS_DEFAULT_REGION="us-east-1"
#   AWS account must have Amazon Bedrock available in the target region.

run "create_minimal_guardrail" {
  # SKIP_IN_CI
  command = apply

  module {
    source = "../../"
  }

  variables {
    name        = "integ-bedrock-test"
    environment = "test"

    guardrails = {
      basic-guardrail = {
        description            = "Integration test guardrail — safe to delete"
        blocked_input_message  = "Input blocked by test guardrail."
        blocked_output_message = "Output blocked by test guardrail."

        content_policy_filters = [
          {
            type            = "VIOLENCE"
            input_strength  = "LOW"
            output_strength = "LOW"
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys(var.guardrails)) == 1
    error_message = "One guardrail should be configured for this integration test."
  }
}
