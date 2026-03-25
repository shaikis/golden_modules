# Integration tests — tf-aws-iam-role
# Cost estimate: $0.00 — IAM roles are free.
# These tests CREATE real IAM roles. Remember to run terraform destroy after.
# Run manually: terraform test -filter=tests/integration

# ── Test 1: Create IAM role with EC2 trust policy ────────────────────────────
# SKIP_IN_CI
run "create_iam_role_ec2_trust" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name                  = "tftest-iam-role-ec2"
    description           = "Integration test IAM role — EC2 trust"
    trusted_role_services = ["ec2.amazonaws.com"]
    environment           = "test"
  }

  assert {
    condition     = length(output.role_arn) > 0
    error_message = "role_arn must be non-empty."
  }

  assert {
    condition     = contains(split(":", output.role_arn), "iam")
    error_message = "role_arn must contain 'iam'."
  }

  assert {
    condition     = startswith(output.role_arn, "arn:aws:iam")
    error_message = "role_arn must start with 'arn:aws:iam'."
  }

  assert {
    condition     = length(output.role_name) > 0
    error_message = "role_name must be non-empty."
  }
}

# ── Test 2: Create IAM role with Lambda trust and managed policy ─────────────
# SKIP_IN_CI
run "create_iam_role_lambda_trust" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name                  = "tftest-iam-role-lambda"
    description           = "Integration test IAM role — Lambda trust"
    trusted_role_services = ["lambda.amazonaws.com"]
    managed_policy_arns   = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
    environment           = "test"
  }

  assert {
    condition     = startswith(output.role_arn, "arn:aws:iam")
    error_message = "role_arn must start with 'arn:aws:iam'."
  }

  assert {
    condition     = length(output.role_id) > 0
    error_message = "role_id must be non-empty."
  }
}

# ── Test 3: Create IAM role with instance profile ────────────────────────────
# SKIP_IN_CI
run "create_iam_role_with_instance_profile" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name                     = "tftest-iam-role-profile"
    description              = "Integration test IAM role — with instance profile"
    trusted_role_services    = ["ec2.amazonaws.com"]
    create_instance_profile  = true
    environment              = "test"
  }

  assert {
    condition     = startswith(output.role_arn, "arn:aws:iam")
    error_message = "role_arn must start with 'arn:aws:iam'."
  }

  assert {
    condition     = output.instance_profile_arn != null
    error_message = "instance_profile_arn must be non-null when create_instance_profile = true."
  }

  assert {
    condition     = startswith(output.instance_profile_arn, "arn:aws:iam")
    error_message = "instance_profile_arn must start with 'arn:aws:iam'."
  }
}
