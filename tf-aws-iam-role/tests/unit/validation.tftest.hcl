# Unit tests — variable validation for tf-aws-iam-role
# All tests use command = plan.
# Tests with expect_failures confirm invalid inputs are rejected.

# ── Test 1: max_session_duration at lower bound (3600) is valid ──────────────
run "max_session_duration_lower_bound" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                  = "test-role"
    trusted_role_services = ["lambda.amazonaws.com"]
    max_session_duration  = 3600
  }

  assert {
    condition     = aws_iam_role.this.max_session_duration == 3600
    error_message = "max_session_duration = 3600 (lower bound) must be accepted."
  }
}

# ── Test 2: max_session_duration at upper bound (43200) is valid ─────────────
run "max_session_duration_upper_bound" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                  = "test-role"
    trusted_role_services = ["lambda.amazonaws.com"]
    max_session_duration  = 43200
  }

  assert {
    condition     = aws_iam_role.this.max_session_duration == 43200
    error_message = "max_session_duration = 43200 (upper bound) must be accepted."
  }
}

# ── Test 3: max_session_duration below lower bound is rejected ───────────────
run "max_session_duration_too_low_rejected" {
  command = plan

  expect_failures = [var.max_session_duration]

  module {
    source = "../../"
  }

  variables {
    name                  = "test-role"
    trusted_role_services = ["lambda.amazonaws.com"]
    max_session_duration  = 3599
  }
}

# ── Test 4: max_session_duration above upper bound is rejected ───────────────
run "max_session_duration_too_high_rejected" {
  command = plan

  expect_failures = [var.max_session_duration]

  module {
    source = "../../"
  }

  variables {
    name                  = "test-role"
    trusted_role_services = ["lambda.amazonaws.com"]
    max_session_duration  = 43201
  }
}

# ── Test 5: permissions_boundary ARN propagated to role ─────────────────────
run "permissions_boundary_propagated" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                  = "bounded-role"
    trusted_role_services = ["lambda.amazonaws.com"]
    permissions_boundary  = "arn:aws:iam::123456789012:policy/BoundaryPolicy"
  }

  assert {
    condition     = aws_iam_role.this.permissions_boundary == "arn:aws:iam::123456789012:policy/BoundaryPolicy"
    error_message = "permissions_boundary must be propagated to the IAM role."
  }
}

# ── Test 6: Custom trusted_role_actions applied ──────────────────────────────
run "custom_trusted_role_actions" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                  = "sts-tagging-role"
    trusted_role_arns     = ["arn:aws:iam::123456789012:role/test-role"]
    trusted_role_actions  = ["sts:AssumeRole", "sts:TagSession"]
  }

  assert {
    condition     = aws_iam_role.this.name == "sts-tagging-role"
    error_message = "Role with custom trusted_role_actions must be planned successfully."
  }
}

# ── Test 7: Multiple managed policy ARNs attached ────────────────────────────
run "multiple_managed_policy_arns" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                  = "multi-policy-role"
    trusted_role_services = ["lambda.amazonaws.com"]
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
      "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess",
    ]
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.managed) == 2
    error_message = "Expected two managed policy attachments."
  }
}

# ── Test 8: Inline policies attached ─────────────────────────────────────────
run "inline_policies_attached" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                  = "inline-role"
    trusted_role_services = ["lambda.amazonaws.com"]
    inline_policies = {
      "s3-write" = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect   = "Allow"
          Action   = ["s3:PutObject"]
          Resource = "arn:aws:s3:::my-bucket/*"
        }]
      })
    }
  }

  assert {
    condition     = length(aws_iam_role_policy.inline) == 1
    error_message = "Expected one inline policy resource."
  }
}

# ── Test 9: assume_role_conditions applied ───────────────────────────────────
run "assume_role_conditions_applied" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                  = "conditional-role"
    trusted_role_arns     = ["arn:aws:iam::123456789012:role/test-role"]
    assume_role_conditions = [
      {
        test     = "StringEquals"
        variable = "sts:ExternalId"
        values   = ["my-external-id"]
      }
    ]
  }

  assert {
    condition     = aws_iam_role.this.name == "conditional-role"
    error_message = "Role with assume_role_conditions must be planned successfully."
  }
}
