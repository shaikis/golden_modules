# Unit tests — variable validation for tf-aws-kms
# All tests use command = plan. Tests prefixed with expect_failures
# confirm that invalid inputs are correctly rejected by validation rules.

# ── Test 1: Valid key_usage value is accepted ────────────────────────────────
run "valid_key_usage_encrypt_decrypt" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    keys = {
      "s3" = {
        description = "S3 key"
        key_usage   = "ENCRYPT_DECRYPT"
      }
    }
  }

  assert {
    condition     = aws_kms_key.this["s3"].key_usage == "ENCRYPT_DECRYPT"
    error_message = "key_usage ENCRYPT_DECRYPT must be accepted."
  }
}

# ── Test 2: SIGN_VERIFY key_usage accepted ───────────────────────────────────
run "valid_key_usage_sign_verify" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    keys = {
      "signing" = {
        description              = "Signing key"
        key_usage                = "SIGN_VERIFY"
        customer_master_key_spec = "RSA_2048"
        enable_key_rotation      = false
      }
    }
  }

  assert {
    condition     = aws_kms_key.this["signing"].key_usage == "SIGN_VERIFY"
    error_message = "key_usage SIGN_VERIFY must be accepted."
  }
}

# ── Test 3: deletion_window_in_days within valid range ───────────────────────
run "valid_deletion_window" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    keys = {
      "s3" = {
        description             = "S3 key"
        deletion_window_in_days = 7
      }
    }
  }

  assert {
    condition     = aws_kms_key.this["s3"].deletion_window_in_days == 7
    error_message = "deletion_window_in_days = 7 must be accepted."
  }
}

# ── Test 4: rotation_period_in_days accepts custom value ────────────────────
run "valid_rotation_period" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    keys = {
      "s3" = {
        description             = "S3 key"
        rotation_period_in_days = 90
      }
    }
  }

  assert {
    condition     = aws_kms_key.this["s3"].rotation_period_in_days == 90
    error_message = "rotation_period_in_days = 90 must be accepted."
  }
}

# ── Test 5: name_prefix defaults to "prod" ───────────────────────────────────
run "name_prefix_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    keys = {
      "s3" = { description = "S3 key" }
    }
  }

  assert {
    condition     = startswith(aws_kms_alias.primary["s3"].name, "alias/prod/")
    error_message = "Default name_prefix 'prod' must appear in alias name."
  }
}

# ── Test 6: SYMMETRIC_DEFAULT customer_master_key_spec accepted ─────────────
run "valid_cmk_spec_symmetric" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    keys = {
      "s3" = {
        description              = "S3 key"
        customer_master_key_spec = "SYMMETRIC_DEFAULT"
      }
    }
  }

  assert {
    condition     = aws_kms_key.this["s3"].customer_master_key_spec == "SYMMETRIC_DEFAULT"
    error_message = "customer_master_key_spec SYMMETRIC_DEFAULT must be accepted."
  }
}
