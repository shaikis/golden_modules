# SKIP_IN_CI
#
# Integration test — creates real AWS resources.
# Requires valid AWS credentials with the following minimum permissions:
#   - iam:CreateRole
#   - iam:AttachRolePolicy
#   - iam:GetRole
#   - iam:DeleteRole
#   - iam:DetachRolePolicy
#   - sts:GetCallerIdentity
#
# Run manually against a sandbox account:
#   terraform test -filter=tests/integration/basic.tftest.hcl
#
# Resources created:  1 × aws_iam_role  (no cost)
# Cleanup:            automatic via teardown destroy block

# ---------------------------------------------------------------------------
# Setup: create only the IAM execution role — all SageMaker gates stay false
# ---------------------------------------------------------------------------
run "iam_role_created_and_output_non_empty" {
  command = apply

  variables {
    name_prefix = "tftest-sagemaker-basic"

    # IAM role only — free tier safe, no SageMaker service calls
    create_iam_role       = true
    create_domains        = false
    create_notebooks      = false
    create_models         = false
    create_endpoints      = false
    create_feature_groups = false
    create_pipelines      = false
    create_alarms         = false

    tags = {
      Environment = "test"
      ManagedBy   = "terraform-test"
      Purpose     = "integration-test"
    }
  }

  # Assert: iam_role_arn output is a non-empty string
  assert {
    condition     = output.iam_role_arn != null && output.iam_role_arn != ""
    error_message = "iam_role_arn output must be a non-empty string after apply."
  }

  # Assert: iam_role_arn follows expected ARN format
  assert {
    condition     = can(regex("^arn:[a-z0-9-]+:iam::[0-9]{12}:role/.+", output.iam_role_arn))
    error_message = "iam_role_arn must match the IAM role ARN format arn:<partition>:iam::<account>:role/<name>."
  }

  # Assert: iam_role_name output is non-null and contains name_prefix
  assert {
    condition     = output.iam_role_name != null
    error_message = "iam_role_name output must be non-null when create_iam_role = true."
  }

  assert {
    condition     = can(regex("^tftest-sagemaker-basic-", output.iam_role_name))
    error_message = "iam_role_name should start with the supplied name_prefix 'tftest-sagemaker-basic-'."
  }

  # Assert: no domain, notebook, model, or endpoint resources were created
  assert {
    condition     = length(output.domain_ids) == 0
    error_message = "No domain IDs should be present when create_domains = false."
  }

  assert {
    condition     = length(output.notebook_arns) == 0
    error_message = "No notebook ARNs should be present when create_notebooks = false."
  }

  assert {
    condition     = length(output.model_arns) == 0
    error_message = "No model ARNs should be present when create_models = false."
  }

  assert {
    condition     = length(output.endpoint_arns) == 0
    error_message = "No endpoint ARNs should be present when create_endpoints = false."
  }

  assert {
    condition     = length(output.feature_group_arns) == 0
    error_message = "No feature group ARNs should be present when create_feature_groups = false."
  }

  assert {
    condition     = length(output.pipeline_arns) == 0
    error_message = "No pipeline ARNs should be present when create_pipelines = false."
  }
}

# ---------------------------------------------------------------------------
# Teardown: destroy all resources created above
# ---------------------------------------------------------------------------
run "teardown" {
  command = apply

  variables {
    name_prefix     = "tftest-sagemaker-basic"
    create_iam_role = false
    role_arn        = "arn:aws:iam::000000000000:role/placeholder-for-destroy"
  }
}
