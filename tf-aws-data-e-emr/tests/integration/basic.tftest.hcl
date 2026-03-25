# Integration test: creates a minimal EMR Serverless application and verifies outputs
# command = apply  →  real AWS resources are created then destroyed
# SKIP_IN_CI

variables {
  # Use serverless (cheaper, no long-running cluster) for the integration smoke-test
  create_serverless_applications = true

  serverless_applications = {
    etl = {
      type          = "SPARK"
      release_label = "emr-7.0.0"
      max_cpu       = "40vCPU"
      max_memory    = "400GB"
      auto_start    = true
      auto_stop     = true
    }
  }

  # Feature gates: keep optional gates off for minimal footprint
  create_security_configurations = false
  create_studios                 = false
  create_alarms                  = false

  # Auto-create IAM roles
  create_iam_role = true

  tags = {
    env     = "integration-test"
    managed = "terraform-test"
  }
}

# ── Apply: create resources ───────────────────────────────────────────────────

run "creates_serverless_application" {
  # SKIP_IN_CI
  command = apply

  module {
    source = "../../"
  }

  # Serverless application ARN is populated
  assert {
    condition     = length(output.serverless_application_arns) == 1
    error_message = "Expected exactly one serverless application ARN"
  }

  assert {
    condition     = can(regex("^arn:aws:emr-serverless:", values(output.serverless_application_arns)[0]))
    error_message = "Serverless application ARN does not have expected emr-serverless prefix"
  }

  # No classic clusters created
  assert {
    condition     = length(output.cluster_ids) == 0
    error_message = "Expected no cluster IDs when clusters map is empty"
  }

  # Studios were not created
  assert {
    condition     = length(output.studio_ids) == 0
    error_message = "Expected no studio IDs when create_studios = false"
  }

  # IAM service role was auto-created
  assert {
    condition     = can(regex("^arn:aws:iam::", output.emr_service_role_arn))
    error_message = "Expected emr_service_role_arn to be a valid IAM ARN"
  }

  assert {
    condition     = can(regex("^arn:aws:iam::", output.emr_instance_profile_arn))
    error_message = "Expected emr_instance_profile_arn to be a valid IAM ARN"
  }
}
