# tests/unit/defaults.tftest.hcl — tf-aws-secretsmanager
# Verifies defaults, feature gates, and BYO KMS pattern via plan only (free).

variables {
  name          = "test-secret"
  secret_string = "placeholder-value"
}

# ---------------------------------------------------------------------------
# Minimal secret — name + secret_string, all other options at defaults
# ---------------------------------------------------------------------------
run "minimal_secret_creation" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name          = "test-secret"
    secret_string = "my-super-secret-value"
  }
}

# ---------------------------------------------------------------------------
# enable_rotation defaults to false — rotation_lambda_arn is null
# ---------------------------------------------------------------------------
run "rotation_off_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name          = "test-secret"
    secret_string = "value"
  }

  assert {
    condition     = var.rotation_lambda_arn == null
    error_message = "rotation_lambda_arn should default to null (rotation disabled)"
  }

  assert {
    condition     = var.rotation_rules == null
    error_message = "rotation_rules should default to null"
  }
}

# ---------------------------------------------------------------------------
# create_kms_key = false by default — kms_key_id is null unless supplied
# ---------------------------------------------------------------------------
run "kms_key_not_created_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name          = "test-secret"
    secret_string = "value"
  }

  assert {
    condition     = var.kms_key_id == null
    error_message = "kms_key_id should default to null (BYO KMS or AWS managed key)"
  }
}

# ---------------------------------------------------------------------------
# BYO KMS pattern — kms_key_arn provided, no key creation
# ---------------------------------------------------------------------------
run "byo_kms_key" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name          = "test-secret"
    secret_string = "value"
    kms_key_id    = "arn:aws:kms:us-east-1:123456789012:key/abc"
  }

  assert {
    condition     = var.kms_key_id == "arn:aws:kms:us-east-1:123456789012:key/abc"
    error_message = "BYO kms_key_id should be preserved"
  }
}

# ---------------------------------------------------------------------------
# recovery_window_days defaults to 30
# ---------------------------------------------------------------------------
run "recovery_window_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name          = "test-secret"
    secret_string = "value"
  }

  assert {
    condition     = var.recovery_window_days == 30
    error_message = "recovery_window_days should default to 30"
  }
}

# ---------------------------------------------------------------------------
# Replicas default to empty map
# ---------------------------------------------------------------------------
run "replicas_empty_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name          = "test-secret"
    secret_string = "value"
  }

  assert {
    condition     = length(var.replicas) == 0
    error_message = "replicas should default to an empty map"
  }
}
