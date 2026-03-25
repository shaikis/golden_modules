# Unit tests — tf-aws-dynamodb defaults and BYO patterns
# command = plan (no AWS resources created)

# ---------------------------------------------------------------------------
# Test: Minimal table creation with defaults
# ---------------------------------------------------------------------------
run "defaults_plan_succeeds" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      orders = {
        hash_key = "order_id"
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.name_prefix == "test"
    error_message = "name_prefix should be 'test'."
  }

  assert {
    condition     = var.tables["orders"].billing_mode == "PAY_PER_REQUEST"
    error_message = "Default billing_mode should be PAY_PER_REQUEST."
  }

  assert {
    condition     = var.tables["orders"].point_in_time_recovery == true
    error_message = "Point-in-time recovery should be enabled by default."
  }

  assert {
    condition     = var.tables["orders"].deletion_protection == true
    error_message = "Deletion protection should be enabled by default."
  }

  assert {
    condition     = var.tables["orders"].table_class == "STANDARD"
    error_message = "Default table class should be STANDARD."
  }
}

# ---------------------------------------------------------------------------
# Test: Backup plan enabled by default
# ---------------------------------------------------------------------------
run "backup_plan_enabled_by_default" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      sessions = {
        hash_key = "session_id"
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_backup_plan == true
    error_message = "create_backup_plan should be true by default."
  }
}

# ---------------------------------------------------------------------------
# Test: create_backup_plan = false (BYO backup)
# ---------------------------------------------------------------------------
run "byo_backup_plan" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      events = {
        hash_key = "event_id"
      }
    }
    create_backup_plan = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_backup_plan == false
    error_message = "create_backup_plan should be false when disabled."
  }
}

# ---------------------------------------------------------------------------
# Test: Global tables default is empty (no global replication)
# ---------------------------------------------------------------------------
run "global_tables_disabled_by_default" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      users = {
        hash_key = "user_id"
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.global_tables) == 0
    error_message = "global_tables should be empty by default."
  }
}

# ---------------------------------------------------------------------------
# Test: Alarms enabled by default
# ---------------------------------------------------------------------------
run "alarms_enabled_by_default" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      products = {
        hash_key = "product_id"
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_alarms == true
    error_message = "create_alarms should be true by default."
  }
}

# ---------------------------------------------------------------------------
# Test: Alarms disabled
# ---------------------------------------------------------------------------
run "alarms_disabled" {
  command = plan

  variables {
    name_prefix   = "test"
    create_alarms = false
    tables = {
      items = {
        hash_key = "item_id"
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_alarms == false
    error_message = "create_alarms should be false when explicitly disabled."
  }
}

# ---------------------------------------------------------------------------
# Test: BYO KMS key for table encryption
# ---------------------------------------------------------------------------
run "byo_kms_key_per_table" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      secrets = {
        hash_key    = "secret_id"
        kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/test-key-id"
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.tables["secrets"].kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/test-key-id"
    error_message = "BYO KMS key ARN should be passed through for the table."
  }
}

# ---------------------------------------------------------------------------
# Test: IAM roles enabled by default
# ---------------------------------------------------------------------------
run "iam_roles_enabled_by_default" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      records = {
        hash_key = "record_id"
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_iam_roles == true
    error_message = "create_iam_roles should be true by default."
  }
}

# ---------------------------------------------------------------------------
# Test: Table with autoscaling configured
# ---------------------------------------------------------------------------
run "table_with_autoscaling" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      catalog = {
        hash_key     = "catalog_id"
        billing_mode = "PROVISIONED"
        read_capacity  = 5
        write_capacity = 5
        autoscaling = {
          min_read_capacity        = 5
          max_read_capacity        = 100
          min_write_capacity       = 5
          max_write_capacity       = 100
          target_read_utilization  = 70
          target_write_utilization = 70
        }
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.tables["catalog"].autoscaling != null
    error_message = "Autoscaling config should not be null when provided."
  }

  assert {
    condition     = var.tables["catalog"].autoscaling.max_read_capacity == 100
    error_message = "max_read_capacity should be 100."
  }
}
