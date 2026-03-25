# Integration tests — tf-aws-kms
# These tests CREATE real AWS resources and incur cost.
# They are skipped in CI (see SKIP_IN_CI comment on each run block).
# Run manually: terraform test -filter=tests/integration

# ── Test 1: Create a single KMS key and verify outputs ──────────────────────
# SKIP_IN_CI
run "create_single_s3_key" {
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
    keys = {
      "s3" = {
        description             = "Integration test S3 encryption key"
        enable_key_rotation     = true
        deletion_window_in_days = 7
      }
    }
  }

  assert {
    condition     = length(output.key_arns) == 1
    error_message = "Expected exactly one key ARN in output."
  }

  assert {
    condition     = startswith(output.key_arns["s3"], "arn:aws:kms:")
    error_message = "Key ARN must start with 'arn:aws:kms:'."
  }

  assert {
    condition     = output.key_aliases["s3"] == "alias/tftest/s3"
    error_message = "Key alias must be 'alias/tftest/s3'."
  }

  assert {
    condition     = length(output.key_ids["s3"]) > 0
    error_message = "Key ID must be non-empty."
  }

  assert {
    condition     = output.aws_account_id != ""
    error_message = "aws_account_id output must be non-empty."
  }
}

# ── Test 2: BYO pattern — no new keys when keys = {} ────────────────────────
# SKIP_IN_CI
run "empty_module_creates_nothing" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name_prefix = "tftest-empty"
    keys        = {}
    grants      = {}
    replica_keys = {}
  }

  assert {
    condition     = length(output.key_arns) == 0
    error_message = "Expected zero key ARNs when keys = {}."
  }

  assert {
    condition     = length(output.all_key_arns) == 0
    error_message = "Expected zero entries in all_key_arns when keys = {}."
  }
}

# ── Test 3: Multiple keys with tag propagation ───────────────────────────────
# SKIP_IN_CI
run "multiple_keys_with_tags" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name_prefix = "tftest-multi"
    tags = {
      Environment = "test"
    }
    keys = {
      "rds" = {
        description             = "RDS key"
        deletion_window_in_days = 7
      }
      "s3" = {
        description             = "S3 key"
        deletion_window_in_days = 7
      }
    }
  }

  assert {
    condition     = length(output.key_arns) == 2
    error_message = "Expected two key ARNs in output."
  }

  assert {
    condition     = contains(keys(output.key_arns), "rds") && contains(keys(output.key_arns), "s3")
    error_message = "Output key_arns must contain both 'rds' and 's3' keys."
  }

  assert {
    condition     = output.key_aliases["rds"] == "alias/tftest-multi/rds"
    error_message = "RDS key alias must follow alias/<name_prefix>/<key_name> format."
  }

  assert {
    condition     = output.key_aliases["s3"] == "alias/tftest-multi/s3"
    error_message = "S3 key alias must follow alias/<name_prefix>/<key_name> format."
  }
}
