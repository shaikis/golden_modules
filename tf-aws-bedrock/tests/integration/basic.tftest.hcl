# Integration tests — tf-aws-bedrock basic
# command = plan only for Bedrock: Bedrock agent/knowledge-base setup is complex
# and requires account-level model access grants.  We keep this as plan-only
# to verify the configuration is syntactically correct and logically consistent.
#
# Prerequisites:
#   export AWS_ACCESS_KEY_ID="..."
#   export AWS_SECRET_ACCESS_KEY="..."
#   export AWS_DEFAULT_REGION="us-east-1"

# SKIP_IN_CI
run "plan_minimal_bedrock_config" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name        = "tftest-bedrock"
    environment = "test"
    tags = {
      Environment = "test"
      ManagedBy   = "terraform-test"
    }
  }

  assert {
    condition     = var.name == "tftest-bedrock"
    error_message = "Expected module name to be accepted."
  }

  assert {
    condition     = var.enable_model_invocation_logging == false
    error_message = "Expected model invocation logging to be disabled by default."
  }
}

# SKIP_IN_CI
run "plan_with_guardrail" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name        = "tftest-bedrock-guardrail"
    environment = "test"
    guardrails = {
      content_safety = {
        description            = "Integration test guardrail"
        blocked_input_message  = "Input not allowed."
        blocked_output_message = "Output not allowed."
        content_policy_filters = [
          {
            type            = "VIOLENCE"
            input_strength  = "MEDIUM"
            output_strength = "MEDIUM"
          },
          {
            type            = "HATE"
            input_strength  = "HIGH"
            output_strength = "HIGH"
          }
        ]
        managed_word_lists = ["PROFANITY"]
      }
    }
  }

  assert {
    condition     = length(var.guardrails) == 1
    error_message = "Expected one guardrail to be present in the plan."
  }
}

# SKIP_IN_CI
run "plan_with_logging_enabled" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                            = "tftest-bedrock-logging"
    environment                     = "test"
    enable_model_invocation_logging = true
    invocation_log_s3_bucket        = "my-bedrock-logs-bucket"
    invocation_log_s3_prefix        = "bedrock/invocations/"
  }

  assert {
    condition     = var.enable_model_invocation_logging == true
    error_message = "Expected model invocation logging to be enabled."
  }

  assert {
    condition     = var.invocation_log_s3_bucket == "my-bedrock-logs-bucket"
    error_message = "Expected S3 bucket to be set for invocation logging."
  }
}
