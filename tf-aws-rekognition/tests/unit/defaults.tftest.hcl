# ---------------------------------------------------------------------------
# Unit test: defaults
#
# Verifies that with no inputs supplied (all feature gates default to false):
#   - zero resources are planned
#   - outputs that return maps are empty
#   - the auto-created IAM role is the only resource planned (create_iam_role
#     defaults to true — we also test with it disabled)
#
# command = plan  →  no AWS credentials required
# ---------------------------------------------------------------------------

# ---- Provider mock so plan does not need real credentials ------------------
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
      user_id    = "AIDAAAAAAAAAAAAAAAAAA"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
      dns_suffix = "amazonaws.com"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }
}

# ---------------------------------------------------------------------------
# Test 1: Default config — only IAM role is created (create_iam_role = true)
# ---------------------------------------------------------------------------
run "defaults_only_iam_role_planned" {
  command = plan

  # No inputs — all feature gates are false by default.

  assert {
    condition     = length(aws_rekognition_collection.this) == 0
    error_message = "Expected no collections when create_collections = false."
  }

  assert {
    condition     = length(aws_rekognition_stream_processor.this) == 0
    error_message = "Expected no stream processors when create_stream_processors = false."
  }

  assert {
    condition     = length(aws_rekognition_project.this) == 0
    error_message = "Expected no custom labels projects when create_custom_labels_projects = false."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.stream_processor_errors) == 0
    error_message = "Expected no CloudWatch alarms when create_alarms = false."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.stream_processor_throttles) == 0
    error_message = "Expected no throttle alarms when create_alarms = false."
  }

  # IAM role IS created by default.
  assert {
    condition     = length(aws_iam_role.rekognition) == 1
    error_message = "Expected exactly one IAM role when create_iam_role = true (default)."
  }
}

# ---------------------------------------------------------------------------
# Test 2: BYO IAM role — no role resource should be planned
# ---------------------------------------------------------------------------
run "byo_iam_role_no_role_planned" {
  command = plan

  variables {
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/my-existing-rekognition-role"
  }

  assert {
    condition     = length(aws_iam_role.rekognition) == 0
    error_message = "Expected no IAM role when create_iam_role = false."
  }
}

# ---------------------------------------------------------------------------
# Test 3: name_prefix is reflected in role name
# ---------------------------------------------------------------------------
run "name_prefix_applied_to_role" {
  command = plan

  variables {
    name_prefix = "prod"
  }

  assert {
    condition     = aws_iam_role.rekognition[0].name == "prod-rekognition-role"
    error_message = "Expected role name to be 'prod-rekognition-role' when name_prefix = 'prod'."
  }
}

# ---------------------------------------------------------------------------
# Test 4: module-level tags are merged onto the IAM role
# ---------------------------------------------------------------------------
run "module_tags_merged" {
  command = plan

  variables {
    tags = {
      Environment = "test"
      Team        = "platform"
    }
  }

  assert {
    condition     = aws_iam_role.rekognition[0].tags["ManagedBy"] == "terraform"
    error_message = "Expected ManagedBy = terraform tag on the IAM role."
  }

  assert {
    condition     = aws_iam_role.rekognition[0].tags["Module"] == "tf-aws-rekognition"
    error_message = "Expected Module = tf-aws-rekognition tag on the IAM role."
  }

  assert {
    condition     = aws_iam_role.rekognition[0].tags["Environment"] == "test"
    error_message = "Expected caller-supplied Environment tag to be propagated."
  }
}

# ---------------------------------------------------------------------------
# Test 5: KMS policy is not created when kms_key_arn is null
# ---------------------------------------------------------------------------
run "no_kms_policy_when_key_not_provided" {
  command = plan

  assert {
    condition     = length(aws_iam_role_policy.rekognition_kms) == 0
    error_message = "Expected no KMS inline policy when kms_key_arn is null."
  }
}

# ---------------------------------------------------------------------------
# Test 6: KMS policy IS planned when kms_key_arn is set
# ---------------------------------------------------------------------------
run "kms_policy_planned_when_key_provided" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456"
  }

  assert {
    condition     = length(aws_iam_role_policy.rekognition_kms) == 1
    error_message = "Expected one KMS inline policy when kms_key_arn is provided."
  }
}

# ---------------------------------------------------------------------------
# Test 7: collection gate — enabling gate with map creates resources
# ---------------------------------------------------------------------------
run "collection_gate_enabled" {
  command = plan

  variables {
    create_collections = true
    collections = {
      "faces" = { tags = {} }
    }
  }

  assert {
    condition     = length(aws_rekognition_collection.this) == 1
    error_message = "Expected one collection when create_collections = true and collections map has one entry."
  }
}

# ---------------------------------------------------------------------------
# Test 8: custom labels gate — enabling gate creates project resources
# ---------------------------------------------------------------------------
run "custom_labels_gate_enabled" {
  command = plan

  variables {
    create_custom_labels_projects = true
    custom_labels_projects = {
      "model-a" = { tags = {} }
      "model-b" = { tags = { Owner = "ml-team" } }
    }
  }

  assert {
    condition     = length(aws_rekognition_project.this) == 2
    error_message = "Expected two Custom Labels projects."
  }
}
