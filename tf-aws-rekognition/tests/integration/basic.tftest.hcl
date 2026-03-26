# ---------------------------------------------------------------------------
# Integration test: basic collection lifecycle
#
# # SKIP_IN_CI
#
# This test provisions REAL AWS resources. Run it only against a sandbox
# account with appropriate credentials configured.
#
# Resources created (all destroyed automatically after the test):
#   - 1 x aws_rekognition_collection
#   - 1 x aws_iam_role (auto-created)
#   - 2 x aws_iam_role_policy (permissions + no KMS)
#
# Estimated cost: $0.00  (Rekognition face collections have no idle charge)
#
# Prerequisites:
#   export AWS_REGION=us-east-1
#   export AWS_PROFILE=sandbox    # or AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
#
# Run:
#   terraform test -filter=tests/integration/basic.tftest.hcl
# ---------------------------------------------------------------------------

provider "aws" {
  # Region is picked up from AWS_REGION env var or the active profile.
}

# ---------------------------------------------------------------------------
# Apply: create a single face collection
# ---------------------------------------------------------------------------
run "create_collection" {
  command = apply

  variables {
    create_collections = true

    collections = {
      "integration-test" = {
        tags = { TestRun = "basic" }
      }
    }

    name_prefix = "tftest"

    tags = {
      Environment = "test"
      ManagedBy   = "terraform-test"
      Purpose     = "integration-test"
    }
  }

  # ----- Output assertions ------------------------------------------------

  # collection_ids map must contain the key we declared.
  assert {
    condition     = contains(keys(output.collection_ids), "integration-test")
    error_message = "Expected 'integration-test' key in collection_ids output."
  }

  # The collection_id value must match the prefixed name.
  assert {
    condition     = output.collection_ids["integration-test"] == "tftest-integration-test"
    error_message = "collection_id should be 'tftest-integration-test' (name_prefix + key)."
  }

  # collection_arns map must also contain the key.
  assert {
    condition     = contains(keys(output.collection_arns), "integration-test")
    error_message = "Expected 'integration-test' key in collection_arns output."
  }

  # ARN must match the expected pattern.
  assert {
    condition = can(
      regex(
        "^arn:aws:rekognition:[a-z0-9\\-]+:[0-9]{12}:collection/tftest-integration-test$",
        output.collection_arns["integration-test"]
      )
    )
    error_message = "collection_arn does not match expected ARN pattern."
  }

  # IAM role ARN must be populated.
  assert {
    condition     = output.iam_role_arn != null && output.iam_role_arn != ""
    error_message = "Expected a non-empty iam_role_arn output."
  }

  # IAM role name must carry the name_prefix.
  assert {
    condition     = output.iam_role_name == "tftest-rekognition-role"
    error_message = "Expected iam_role_name = 'tftest-rekognition-role'."
  }

  # No stream processors, alarms, or custom labels projects expected.
  assert {
    condition     = length(output.stream_processor_arns) == 0
    error_message = "Expected no stream processors in a basic collection test."
  }

  assert {
    condition     = length(output.custom_labels_project_arns) == 0
    error_message = "Expected no custom labels projects in a basic collection test."
  }

  assert {
    condition     = length(output.alarm_arns) == 0
    error_message = "Expected no alarms in a basic collection test."
  }
}

# ---------------------------------------------------------------------------
# Plan-only check: adding a second collection does not affect the first
# ---------------------------------------------------------------------------
run "add_second_collection_plan" {
  command = plan

  variables {
    create_collections = true

    collections = {
      "integration-test" = { tags = { TestRun = "basic" } }
      "second-collection" = { tags = { TestRun = "extended" } }
    }

    name_prefix = "tftest"
    tags        = { Environment = "test" }
  }

  assert {
    condition     = length(aws_rekognition_collection.this) == 2
    error_message = "Expected exactly two collections in the plan."
  }
}
