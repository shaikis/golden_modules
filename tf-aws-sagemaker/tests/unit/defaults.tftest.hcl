# Unit tests — default values and structural behaviour
# command = plan only; no AWS credentials or live resources required.

# ---------------------------------------------------------------------------
# Test 1: All create_X feature gates default to false
# ---------------------------------------------------------------------------
run "feature_gates_all_default_false" {
  command = plan

  # No variables set — rely entirely on defaults.
  variables {}

  assert {
    condition     = var.create_domains == false
    error_message = "create_domains should default to false."
  }

  assert {
    condition     = var.create_notebooks == false
    error_message = "create_notebooks should default to false."
  }

  assert {
    condition     = var.create_models == false
    error_message = "create_models should default to false."
  }

  assert {
    condition     = var.create_endpoints == false
    error_message = "create_endpoints should default to false."
  }

  assert {
    condition     = var.create_feature_groups == false
    error_message = "create_feature_groups should default to false."
  }

  assert {
    condition     = var.create_pipelines == false
    error_message = "create_pipelines should default to false."
  }

  assert {
    condition     = var.create_alarms == false
    error_message = "create_alarms should default to false."
  }
}

# ---------------------------------------------------------------------------
# Test 2: create_iam_role defaults to true; role is planned
# ---------------------------------------------------------------------------
run "create_iam_role_defaults_true" {
  command = plan

  variables {}

  assert {
    condition     = var.create_iam_role == true
    error_message = "create_iam_role should default to true."
  }

  assert {
    condition     = length(aws_iam_role.sagemaker) == 1
    error_message = "Exactly one IAM role should be planned when create_iam_role = true."
  }
}

# ---------------------------------------------------------------------------
# Test 3: BYO role pattern — create_iam_role=false + role_arn provided
#         No IAM role resource should be planned.
# ---------------------------------------------------------------------------
run "byo_role_no_iam_role_resource_planned" {
  command = plan

  variables {
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/my-existing-sagemaker-role"
  }

  assert {
    condition     = length(aws_iam_role.sagemaker) == 0
    error_message = "No IAM role resource should be planned when create_iam_role = false."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.sagemaker_full) == 0
    error_message = "No IAM policy attachment should be planned when create_iam_role = false."
  }
}

# ---------------------------------------------------------------------------
# Test 4: name_prefix is applied to the IAM role name
# ---------------------------------------------------------------------------
run "name_prefix_applied_to_iam_role" {
  command = plan

  variables {
    name_prefix = "myapp-prod"
  }

  assert {
    condition     = aws_iam_role.sagemaker[0].name == "myapp-prod-sagemaker-execution-role"
    error_message = "IAM role name should be prefixed with 'myapp-prod-'."
  }
}

# ---------------------------------------------------------------------------
# Test 5: Empty name_prefix produces no leading dash
# ---------------------------------------------------------------------------
run "empty_name_prefix_no_dash" {
  command = plan

  variables {
    name_prefix = ""
  }

  assert {
    condition     = aws_iam_role.sagemaker[0].name == "sagemaker-execution-role"
    error_message = "IAM role name should have no leading dash when name_prefix is empty."
  }
}

# ---------------------------------------------------------------------------
# Test 6: Tags are merged — module stamps + caller tags both present
# ---------------------------------------------------------------------------
run "tags_merged_correctly" {
  command = plan

  variables {
    tags = {
      Environment = "dev"
      Team        = "ml-platform"
    }
  }

  assert {
    condition     = aws_iam_role.sagemaker[0].tags["ManagedBy"] == "terraform"
    error_message = "ManagedBy tag should be 'terraform'."
  }

  assert {
    condition     = aws_iam_role.sagemaker[0].tags["Module"] == "tf-aws-sagemaker"
    error_message = "Module tag should be 'tf-aws-sagemaker'."
  }

  assert {
    condition     = aws_iam_role.sagemaker[0].tags["Environment"] == "dev"
    error_message = "Caller-supplied Environment tag should be present."
  }

  assert {
    condition     = aws_iam_role.sagemaker[0].tags["Team"] == "ml-platform"
    error_message = "Caller-supplied Team tag should be present."
  }
}

# ---------------------------------------------------------------------------
# Test 7: Notebooks planned with correct name when create_notebooks = true
# ---------------------------------------------------------------------------
run "notebook_name_prefix_applied" {
  command = plan

  variables {
    name_prefix      = "proj"
    create_notebooks = true
    notebooks = {
      "explore" = {
        instance_type = "ml.t3.medium"
      }
    }
  }

  assert {
    condition     = aws_sagemaker_notebook_instance.this["explore"].name == "proj-explore"
    error_message = "Notebook instance name should be 'proj-explore'."
  }
}

# ---------------------------------------------------------------------------
# Test 8: No notebooks planned when create_notebooks = false (default)
# ---------------------------------------------------------------------------
run "no_notebooks_when_gate_false" {
  command = plan

  variables {
    notebooks = {
      "explore" = {
        instance_type = "ml.t3.medium"
      }
    }
  }

  assert {
    condition     = length(aws_sagemaker_notebook_instance.this) == 0
    error_message = "No notebook resources should be planned when create_notebooks = false."
  }
}
