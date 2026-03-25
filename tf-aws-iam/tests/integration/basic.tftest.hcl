# Integration tests — tf-aws-iam
# These tests CREATE real AWS resources and incur cost.
# They are skipped in CI (see SKIP_IN_CI comment on each run block).
# Run manually: terraform test -filter=tests/integration

# ── Test 1: Create a single IAM role with service principal ─────────────────
# SKIP_IN_CI
run "create_single_role" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name_prefix = "tftest"
    tags = {
      Environment = "test"
      ManagedBy   = "terraform-test"
    }
    roles = {
      "app" = {
        description        = "Integration test application role"
        service_principals = ["lambda.amazonaws.com"]
      }
    }
  }

  assert {
    condition     = length(aws_iam_role.this) == 1
    error_message = "Expected exactly one IAM role to be created."
  }

  assert {
    condition     = aws_iam_role.this["app"].name == "tftest-app"
    error_message = "Role name must be 'tftest-app'."
  }

  assert {
    condition     = startswith(aws_iam_role.this["app"].arn, "arn:aws:iam::")
    error_message = "Role ARN must start with 'arn:aws:iam::'."
  }

  assert {
    condition     = aws_iam_role.this["app"].tags["Environment"] == "test"
    error_message = "Role must carry the 'Environment=test' tag."
  }
}

# ── Test 2: Role with instance profile ───────────────────────────────────────
# SKIP_IN_CI
run "create_role_with_instance_profile" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name_prefix = "tftest-ec2"
    tags = {
      Environment = "test"
    }
    roles = {
      "ec2" = {
        description             = "EC2 instance role for integration test"
        service_principals      = ["ec2.amazonaws.com"]
        create_instance_profile = true
      }
    }
  }

  assert {
    condition     = length(aws_iam_instance_profile.this) == 1
    error_message = "Expected one instance profile to be created."
  }

  assert {
    condition     = startswith(aws_iam_instance_profile.this["ec2"].arn, "arn:aws:iam::")
    error_message = "Instance profile ARN must start with 'arn:aws:iam::'."
  }
}

# ── Test 3: Standalone managed policy ────────────────────────────────────────
# SKIP_IN_CI
run "create_standalone_policy" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name_prefix = "tftest-pol"
    roles       = {}
    policies = {
      "s3-read" = {
        description = "Integration test S3 read policy"
        policy_json = jsonencode({
          Version = "2012-10-17"
          Statement = [{
            Effect   = "Allow"
            Action   = ["s3:GetObject", "s3:ListBucket"]
            Resource = "*"
          }]
        })
      }
    }
  }

  assert {
    condition     = length(aws_iam_policy.this) == 1
    error_message = "Expected one standalone IAM policy to be created."
  }

  assert {
    condition     = startswith(aws_iam_policy.this["s3-read"].arn, "arn:aws:iam::")
    error_message = "Policy ARN must start with 'arn:aws:iam::'."
  }

  assert {
    condition     = aws_iam_policy.this["s3-read"].name == "tftest-pol-s3-read"
    error_message = "Policy name must be 'tftest-pol-s3-read'."
  }
}

# ── Test 4: BYO pattern — no roles when roles = {} ──────────────────────────
# SKIP_IN_CI
run "empty_module_creates_nothing" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name_prefix = "tftest-empty"
    roles       = {}
    policies    = {}
  }

  assert {
    condition     = length(aws_iam_role.this) == 0
    error_message = "Expected zero IAM roles when roles = {}."
  }

  assert {
    condition     = length(aws_iam_policy.this) == 0
    error_message = "Expected zero IAM policies when policies = {}."
  }
}
