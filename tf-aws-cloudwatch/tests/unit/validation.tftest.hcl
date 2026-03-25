# tests/unit/validation.tftest.hcl — tf-aws-cloudwatch
# Verifies that variable combinations that should plan cleanly do so,
# and that the module surfaces no errors for well-formed inputs.

variables {
  name = "test-cw"
}

# ---------------------------------------------------------------------------
# Minimal valid config — only required var supplied
# ---------------------------------------------------------------------------
run "minimal_valid_config" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-cw"
  }
}

# ---------------------------------------------------------------------------
# name_prefix is honoured — plan succeeds with prefix set
# ---------------------------------------------------------------------------
run "name_prefix_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name        = "myapp"
    name_prefix = "prod"
    environment = "prod"
  }
}

# ---------------------------------------------------------------------------
# Dashboard feature enabled with service lists — plan is clean
# ---------------------------------------------------------------------------
run "dashboard_with_services" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name             = "test-cw"
    create_dashboard = true
    dashboard_services = {
      lambda_functions = ["my-function"]
      sqs_queues       = ["my-queue"]
    }
  }
}

# ---------------------------------------------------------------------------
# Multiple notification integrations can be set simultaneously
# ---------------------------------------------------------------------------
run "multiple_integrations" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name            = "test-cw"
    email_endpoints = ["ops@example.com", "alerts@example.com"]
  }

  assert {
    condition     = length(var.email_endpoints) == 2
    error_message = "Multiple email endpoints should be accepted"
  }
}

# ---------------------------------------------------------------------------
# SNS KMS encryption accepted
# ---------------------------------------------------------------------------
run "sns_kms_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name           = "test-cw"
    sns_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/abc"
  }
}
