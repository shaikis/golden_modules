# Unit tests — defaults and feature gates for tf-aws-kms
# command = plan means NO real AWS resources are created.

# ── Test 1: Empty keys map produces no keys ─────────────────────────────────
run "empty_keys_no_resources" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    keys = {}
  }

  assert {
    condition     = length(aws_kms_key.this) == 0
    error_message = "Expected no KMS keys when keys = {}."
  }

  assert {
    condition     = length(aws_kms_alias.primary) == 0
    error_message = "Expected no aliases when keys = {}."
  }
}

# ── Test 2: Minimal single key — enable_key_rotation defaults true ───────────
run "single_key_defaults" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    keys = {
      "s3" = {
        description = "S3 encryption key"
      }
    }
  }

  assert {
    condition     = length(aws_kms_key.this) == 1
    error_message = "Expected exactly one KMS key to be planned."
  }

  assert {
    condition     = aws_kms_key.this["s3"].enable_key_rotation == true
    error_message = "enable_key_rotation must default to true."
  }

  assert {
    condition     = aws_kms_key.this["s3"].deletion_window_in_days == 30
    error_message = "deletion_window_in_days must default to 30."
  }

  assert {
    condition     = aws_kms_key.this["s3"].is_enabled == true
    error_message = "is_enabled must default to true."
  }

  assert {
    condition     = aws_kms_key.this["s3"].multi_region == false
    error_message = "multi_region must default to false."
  }
}

# ── Test 3: Key alias contains name_prefix ──────────────────────────────────
run "key_alias_contains_name_prefix" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "myproject"
    keys = {
      "dynamo" = {
        description = "DynamoDB encryption key"
      }
    }
  }

  assert {
    condition     = startswith(aws_kms_alias.primary["dynamo"].name, "alias/myproject/")
    error_message = "Key alias must start with 'alias/<name_prefix>/'."
  }
}

# ── Test 4: grants map defaults to empty — no grants created ────────────────
run "grants_empty_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    keys = {
      "s3" = { description = "S3 key" }
    }
    grants = {}
  }

  assert {
    condition     = length(aws_kms_grant.this) == 0
    error_message = "Expected no KMS grants when grants = {}."
  }
}

# ── Test 5: replica_keys defaults to empty ──────────────────────────────────
run "replica_keys_empty_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    keys = {}
  }

  assert {
    condition     = length(aws_kms_replica_key.this) == 0
    error_message = "Expected no replica keys when replica_keys = {}."
  }
}

# ── Test 6: Tag propagation ──────────────────────────────────────────────────
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
    keys = {
      "s3" = { description = "S3 key" }
    }
  }

  assert {
    condition     = aws_kms_key.this["s3"].tags["Environment"] == "test"
    error_message = "Module-level tag 'Environment' must propagate to KMS key."
  }

  assert {
    condition     = aws_kms_key.this["s3"].tags["Team"] == "platform"
    error_message = "Module-level tag 'Team' must propagate to KMS key."
  }
}

# ── Test 7: Multiple keys in a single plan ───────────────────────────────────
run "multiple_keys" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = "test"
    keys = {
      "s3"    = { description = "S3 key" }
      "rds"   = { description = "RDS key" }
      "glue"  = { description = "Glue key" }
    }
  }

  assert {
    condition     = length(aws_kms_key.this) == 3
    error_message = "Expected 3 KMS keys to be planned."
  }

  assert {
    condition     = length(aws_kms_alias.primary) == 3
    error_message = "Expected 3 primary aliases to be planned."
  }
}
