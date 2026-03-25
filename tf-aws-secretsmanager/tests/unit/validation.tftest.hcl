# tests/unit/validation.tftest.hcl — tf-aws-secretsmanager
# Confirms well-formed variable combinations plan without errors.

variables {
  name          = "test-secret"
  secret_string = "placeholder"
}

# ---------------------------------------------------------------------------
# Minimal valid config
# ---------------------------------------------------------------------------
run "minimal_valid_config" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name          = "test-secret"
    secret_string = "my-value"
  }
}

# ---------------------------------------------------------------------------
# Custom description accepted
# ---------------------------------------------------------------------------
run "custom_description" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name          = "test-secret"
    secret_string = "value"
    description   = "Database password for myapp"
  }

  assert {
    condition     = var.description == "Database password for myapp"
    error_message = "Custom description should be accepted"
  }
}

# ---------------------------------------------------------------------------
# Rotation config accepted when lambda ARN is provided
# ---------------------------------------------------------------------------
run "rotation_config_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                = "test-secret"
    secret_string       = "value"
    rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:my-rotator"
    rotation_rules = {
      automatically_after_days = 30
    }
  }
}

# ---------------------------------------------------------------------------
# name_prefix accepted
# ---------------------------------------------------------------------------
run "name_prefix_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name          = "db-password"
    name_prefix   = "prod"
    secret_string = "value"
  }
}

# ---------------------------------------------------------------------------
# Tags accepted
# ---------------------------------------------------------------------------
run "tags_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name          = "test-secret"
    secret_string = "value"
    tags = {
      Team = "backend"
    }
  }

  assert {
    condition     = var.tags["Team"] == "backend"
    error_message = "Custom tags should be accepted"
  }
}
