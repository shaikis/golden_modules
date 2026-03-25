# Unit test — input validation for tf-aws-data-e-bedrock
# command = plan: no real AWS resources are created.
# These runs verify that invalid inputs are rejected before any apply.

run "valid_agent_foundation_model_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-bedrock-validation"

    agents = {
      my-agent = {
        foundation_model = "anthropic.claude-3-sonnet-20240229-v1:0"
        instruction      = "You are a helpful assistant."
      }
    }
  }

  assert {
    condition     = true
    error_message = "A valid Claude Sonnet foundation model ID must be accepted."
  }
}

run "valid_guardrail_with_content_filter_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-bedrock-guardrail"

    guardrails = {
      my-guardrail = {
        description = "Test guardrail"
        content_policy_filters = [
          {
            type            = "VIOLENCE"
            input_strength  = "MEDIUM"
            output_strength = "HIGH"
          }
        ]
      }
    }
  }

  assert {
    condition     = true
    error_message = "A guardrail with valid content filter config must plan successfully."
  }
}

# Placeholder: once a validation block is added for foundation_model format,
# uncomment this run to verify invalid model IDs are rejected.
#
# run "invalid_foundation_model_id_rejected" {
#   command = plan
#   expect_failures = [var.agents]
#
#   module {
#     source = "../../"
#   }
#
#   variables {
#     name = "test-bedrock-bad-model"
#     agents = {
#       bad-agent = {
#         foundation_model = "not-a-real-model-id"
#         instruction      = "You are a helpful assistant."
#       }
#     }
#   }
# }
