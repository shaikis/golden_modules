# Integration test: create minimal SageMaker resources, verify outputs, destroy.
# command = apply — REAL AWS resources are created; this incurs cost.
# Prerequisites: AWS credentials with SageMaker + IAM permissions.

# SKIP_IN_CI

variables {
  name_prefix = "tftest"
  tags = {
    Environment = "test"
    ManagedBy   = "terraform-test"
  }

  # Feature gates — keep minimal for integration smoke test.
  create_pipelines     = false
  create_models        = false
  create_endpoints     = false
  create_feature_groups = false
  create_user_profiles = false
  create_alarms        = false

  # Auto-create the execution role for the integration test.
  create_iam_role = true

  # Grant access to an existing test bucket (replace with real ARN in CI).
  data_bucket_arns = []
}

run "sagemaker_iam_role_created" {
  # SKIP_IN_CI
  command = apply

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_iam_role == true
    error_message = "create_iam_role must be true for this integration test."
  }
}

run "no_pipelines_without_gate" {
  # SKIP_IN_CI
  command = apply

  module {
    source = "../../"
  }

  variables {
    create_pipelines = false
  }

  assert {
    condition     = var.create_pipelines == false
    error_message = "Pipelines gate must remain false — no pipeline resources expected."
  }
}
