# Unit tests — tf-aws-bedrock variable validation
# command = plan: no real AWS resources are created.

run "name_required_and_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "my-bedrock"
  }

  assert {
    condition     = var.name == "my-bedrock"
    error_message = "Expected name to be accepted as supplied."
  }
}

run "logging_disabled_without_s3_bucket_ok" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                             = "test-bedrock"
    enable_model_invocation_logging  = false
    invocation_log_s3_bucket         = null
  }

  # Logging is off and no bucket is set — this is the safe default and must pass.
  assert {
    condition     = var.enable_model_invocation_logging == false
    error_message = "Expected logging=false with no bucket to be valid."
  }
}

run "logging_enabled_with_s3_bucket_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                             = "test-bedrock"
    enable_model_invocation_logging  = true
    invocation_log_s3_bucket         = "my-logging-bucket"
  }

  assert {
    condition     = var.enable_model_invocation_logging == true
    error_message = "Expected enable_model_invocation_logging=true with bucket to be accepted."
  }

  assert {
    condition     = var.invocation_log_s3_bucket == "my-logging-bucket"
    error_message = "Expected invocation_log_s3_bucket to reflect the supplied value."
  }
}

run "guardrail_with_full_config_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-bedrock"
    guardrails = {
      safe = {
        description = "Basic content guardrail"
        content_policy_filters = [
          {
            type            = "VIOLENCE"
            input_strength  = "HIGH"
            output_strength = "HIGH"
          }
        ]
      }
    }
  }

  assert {
    condition     = length(var.guardrails) == 1
    error_message = "Expected one guardrail to be accepted."
  }
}

run "environment_tag_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name        = "test-bedrock"
    environment = "production"
  }

  assert {
    condition     = var.environment == "production"
    error_message = "Expected environment variable to accept 'production'."
  }
}
