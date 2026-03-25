# Unit tests — variable validation for tf-aws-iam
# All tests use command = plan.

# ── Test 1: Role with explicit name override ─────────────────────────────────
run "role_explicit_name_override" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "myapp"
    roles = {
      "glue" = {
        name               = "custom-glue-role"
        service_principals = ["glue.amazonaws.com"]
      }
    }
  }

  assert {
    condition     = aws_iam_role.this["glue"].name == "custom-glue-role"
    error_message = "Explicit 'name' must override the auto-generated name."
  }
}

# ── Test 2: Role path defaults to "/" ────────────────────────────────────────
run "role_path_default" {
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
    condition     = aws_iam_role.this["app"].path == "/"
    error_message = "Role path must default to '/'."
  }
}

# ── Test 3: Role with custom path ────────────────────────────────────────────
run "role_custom_path" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    roles = {
      "app" = {
        path               = "/service-roles/"
        service_principals = ["glue.amazonaws.com"]
      }
    }
  }

  assert {
    condition     = aws_iam_role.this["app"].path == "/service-roles/"
    error_message = "Custom role path '/service-roles/' must be accepted."
  }
}

# ── Test 4: Custom max_session_duration accepted ─────────────────────────────
run "custom_max_session_duration" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    roles = {
      "app" = {
        max_session_duration = 7200
        service_principals   = ["ecs-tasks.amazonaws.com"]
      }
    }
  }

  assert {
    condition     = aws_iam_role.this["app"].max_session_duration == 7200
    error_message = "max_session_duration = 7200 must be accepted and propagated."
  }
}

# ── Test 5: Standalone policy creation ───────────────────────────────────────
run "standalone_policy_created" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    roles       = {}
    policies = {
      "s3-read" = {
        description = "S3 read-only policy"
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
    error_message = "Expected one standalone policy to be planned."
  }
}

# ── Test 6: Permission boundary ARN propagated to role ───────────────────────
run "permission_boundary_propagated" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    roles = {
      "app" = {
        description             = "Bounded role"
        service_principals      = ["lambda.amazonaws.com"]
        permission_boundary_arn = "arn:aws:iam::123456789012:policy/BoundaryPolicy"
      }
    }
  }

  assert {
    condition     = aws_iam_role.this["app"].permissions_boundary == "arn:aws:iam::123456789012:policy/BoundaryPolicy"
    error_message = "permission_boundary_arn must be propagated to the IAM role's permissions_boundary."
  }
}

# ── Test 7: Managed policy ARNs attached ─────────────────────────────────────
run "managed_policy_arns_attached" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    roles = {
      "lambda" = {
        service_principals  = ["lambda.amazonaws.com"]
        managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
      }
    }
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.managed) == 1
    error_message = "Expected one managed policy attachment."
  }
}

# ── Test 8: Inline policies attached ─────────────────────────────────────────
run "inline_policies_attached" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    roles = {
      "app" = {
        service_principals = ["lambda.amazonaws.com"]
        inline_policies = {
          "s3-access" = jsonencode({
            Version = "2012-10-17"
            Statement = [{
              Effect   = "Allow"
              Action   = ["s3:PutObject"]
              Resource = "arn:aws:s3:::my-bucket/*"
            }]
          })
        }
      }
    }
  }

  assert {
    condition     = length(aws_iam_role_policy.inline) == 1
    error_message = "Expected one inline policy resource."
  }
}
