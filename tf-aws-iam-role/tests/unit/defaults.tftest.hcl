# Unit tests — defaults and feature gates for tf-aws-iam-role
# command = plan means NO real AWS resources are created.

# ── Test 1: Basic role with service principal ────────────────────────────────
run "basic_role_service_principal" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                  = "test-role"
    trusted_role_services = ["lambda.amazonaws.com"]
  }

  assert {
    condition     = aws_iam_role.this.name == "test-role"
    error_message = "Role name must equal the 'name' variable when name_prefix is empty."
  }
}

# ── Test 2: name_prefix prepended to role name ───────────────────────────────
run "name_prefix_prepended" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix           = "myapp"
    name                  = "glue-role"
    trusted_role_services = ["glue.amazonaws.com"]
  }

  assert {
    condition     = aws_iam_role.this.name == "myapp-glue-role"
    error_message = "Role name must be '<name_prefix>-<name>' when name_prefix is set."
  }
}

# ── Test 3: create_instance_profile defaults to false ───────────────────────
run "instance_profile_not_created_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                  = "ec2-role"
    trusted_role_services = ["ec2.amazonaws.com"]
    # create_instance_profile omitted — must default to false
  }

  assert {
    condition     = length(aws_iam_instance_profile.this) == 0
    error_message = "Instance profile must not be created when create_instance_profile defaults to false."
  }
}

# ── Test 4: create_instance_profile = true creates a profile ────────────────
run "instance_profile_created_when_enabled" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                    = "ec2-role"
    trusted_role_services   = ["ec2.amazonaws.com"]
    create_instance_profile = true
  }

  assert {
    condition     = length(aws_iam_instance_profile.this) == 1
    error_message = "Expected one instance profile when create_instance_profile = true."
  }
}

# ── Test 5: max_session_duration defaults to 3600 ───────────────────────────
run "max_session_duration_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                  = "test-role"
    trusted_role_services = ["lambda.amazonaws.com"]
  }

  assert {
    condition     = aws_iam_role.this.max_session_duration == 3600
    error_message = "max_session_duration must default to 3600 seconds."
  }
}

# ── Test 6: force_detach_policies defaults to true ──────────────────────────
run "force_detach_policies_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                  = "test-role"
    trusted_role_services = ["lambda.amazonaws.com"]
  }

  assert {
    condition     = aws_iam_role.this.force_detach_policies == true
    error_message = "force_detach_policies must default to true."
  }
}

# ── Test 7: description defaults to "Managed by Terraform" ──────────────────
run "description_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                  = "test-role"
    trusted_role_services = ["lambda.amazonaws.com"]
  }

  assert {
    condition     = aws_iam_role.this.description == "Managed by Terraform"
    error_message = "description must default to 'Managed by Terraform'."
  }
}

# ── Test 8: trusted_role_arns trust policy ───────────────────────────────────
run "trusted_role_arns_trust" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name              = "cross-account-role"
    trusted_role_arns = ["arn:aws:iam::123456789012:role/test-role"]
  }

  assert {
    condition     = aws_iam_role.this.name == "cross-account-role"
    error_message = "Role with trusted_role_arns must be planned successfully."
  }
}

# ── Test 9: custom_trust_policy overrides built-in generation ───────────────
run "custom_trust_policy_override" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "custom-trust-role"
    custom_trust_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect    = "Allow"
        Principal = { Service = "glue.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }]
    })
  }

  assert {
    condition     = aws_iam_role.this.name == "custom-trust-role"
    error_message = "Role with custom trust policy must be planned."
  }
}

# ── Test 10: Tag propagation ─────────────────────────────────────────────────
run "tag_propagation" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                  = "tagged-role"
    trusted_role_services = ["lambda.amazonaws.com"]
    tags = {
      Environment = "test"
      Team        = "platform"
    }
  }

  assert {
    condition     = aws_iam_role.this.tags["Environment"] == "test"
    error_message = "Tag 'Environment' must propagate to the IAM role."
  }

  assert {
    condition     = aws_iam_role.this.tags["Team"] == "platform"
    error_message = "Tag 'Team' must propagate to the IAM role."
  }
}

# ── Test 11: environment tag included in default tags ───────────────────────
run "environment_in_default_tags" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                  = "env-role"
    environment           = "staging"
    trusted_role_services = ["ecs-tasks.amazonaws.com"]
  }

  assert {
    condition     = aws_iam_role.this.tags["Environment"] == "staging"
    error_message = "The 'environment' variable must appear as the 'Environment' tag."
  }
}

# ── Test 12: managed_policy_arns empty by default — no attachments ───────────
run "no_managed_policy_attachments_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                  = "bare-role"
    trusted_role_services = ["lambda.amazonaws.com"]
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.managed) == 0
    error_message = "Expected no managed policy attachments when managed_policy_arns defaults to []."
  }
}
