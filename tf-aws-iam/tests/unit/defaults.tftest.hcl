# Unit tests — defaults and feature gates for tf-aws-iam
# command = plan means NO real AWS resources are created.

# ── Test 1: Empty roles map creates no roles ─────────────────────────────────
run "empty_roles_no_resources" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    roles = {}
  }

  assert {
    condition     = length(aws_iam_role.this) == 0
    error_message = "Expected no IAM roles when roles = {}."
  }
}

# ── Test 2: Minimal role with service principal ──────────────────────────────
run "minimal_role_service_principal" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    roles = {
      "app" = {
        description        = "Application role"
        service_principals = ["ec2.amazonaws.com"]
      }
    }
  }

  assert {
    condition     = length(aws_iam_role.this) == 1
    error_message = "Expected exactly one IAM role to be planned."
  }
}

# ── Test 3: create_instance_profile defaults to false ───────────────────────
run "instance_profile_not_created_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    roles = {
      "app" = {
        description        = "App role"
        service_principals = ["ec2.amazonaws.com"]
        # create_instance_profile omitted — must default to false
      }
    }
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
    name_prefix = "test"
    roles = {
      "ec2" = {
        description             = "EC2 role"
        service_principals      = ["ec2.amazonaws.com"]
        create_instance_profile = true
      }
    }
  }

  assert {
    condition     = length(aws_iam_instance_profile.this) == 1
    error_message = "Expected one instance profile when create_instance_profile = true."
  }
}

# ── Test 5: policies map defaults to empty — no standalone policies created ──
run "standalone_policies_empty_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    roles    = {}
    policies = {}
  }

  assert {
    condition     = length(aws_iam_policy.this) == 0
    error_message = "Expected no standalone policies when policies = {}."
  }
}

# ── Test 6: Role name auto-generated from name_prefix + key ─────────────────
run "role_name_auto_generated" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "myapp"
    roles = {
      "glue" = {
        description        = "Glue role"
        service_principals = ["glue.amazonaws.com"]
      }
    }
  }

  assert {
    condition     = aws_iam_role.this["glue"].name == "myapp-glue"
    error_message = "Role name must be auto-generated as '<name_prefix>-<key>' when name is omitted."
  }
}

# ── Test 7: Tag propagation ──────────────────────────────────────────────────
run "tag_propagation" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    tags = {
      Environment = "test"
      Team        = "platform"
    }
    roles = {
      "app" = {
        description        = "App role"
        service_principals = ["lambda.amazonaws.com"]
      }
    }
  }

  assert {
    condition     = aws_iam_role.this["app"].tags["Environment"] == "test"
    error_message = "Module-level tag 'Environment' must propagate to IAM role."
  }

  assert {
    condition     = aws_iam_role.this["app"].tags["Team"] == "platform"
    error_message = "Module-level tag 'Team' must propagate to IAM role."
  }
}

# ── Test 8: Multiple roles planned ──────────────────────────────────────────
run "multiple_roles" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    roles = {
      "glue"   = { service_principals = ["glue.amazonaws.com"] }
      "lambda" = { service_principals = ["lambda.amazonaws.com"] }
      "ecs"    = { service_principals = ["ecs-tasks.amazonaws.com"] }
    }
  }

  assert {
    condition     = length(aws_iam_role.this) == 3
    error_message = "Expected 3 IAM roles to be planned."
  }
}

# ── Test 9: AWS principal trust accepted ────────────────────────────────────
run "aws_principal_trust" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    roles = {
      "cross-account" = {
        description    = "Cross-account role"
        aws_principals = ["arn:aws:iam::123456789012:root"]
      }
    }
  }

  assert {
    condition     = length(aws_iam_role.this) == 1
    error_message = "Expected one role with AWS principal trust."
  }
}

# ── Test 10: max_session_duration defaults to 3600 ──────────────────────────
run "max_session_duration_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    roles = {
      "app" = {
        service_principals = ["lambda.amazonaws.com"]
      }
    }
  }

  assert {
    condition     = aws_iam_role.this["app"].max_session_duration == 3600
    error_message = "max_session_duration must default to 3600 seconds."
  }
}

# ── Test 11: force_detach_policies defaults to true ─────────────────────────
run "force_detach_policies_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    roles = {
      "app" = {
        service_principals = ["lambda.amazonaws.com"]
      }
    }
  }

  assert {
    condition     = aws_iam_role.this["app"].force_detach_policies == true
    error_message = "force_detach_policies must default to true."
  }
}
