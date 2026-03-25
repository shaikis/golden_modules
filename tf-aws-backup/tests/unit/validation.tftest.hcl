# Unit tests — tf-aws-backup variable validation
# command = plan: no real AWS resources are created.

run "name_required_and_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "my-backup"
  }

  assert {
    condition     = var.name == "my-backup"
    error_message = "Expected name to be accepted as supplied."
  }
}

run "valid_log_retention_days_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name               = "test-backup"
    log_retention_days = 90
  }

  assert {
    condition     = var.log_retention_days == 90
    error_message = "Expected log_retention_days = 90 to be accepted."
  }
}

run "invalid_log_retention_days_rejected" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name               = "test-backup"
    log_retention_days = 99
  }

  # 99 is not a valid CloudWatch retention period.
  expect_failures = [var.log_retention_days]
}

run "zero_log_retention_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name               = "test-backup"
    log_retention_days = 0
  }

  assert {
    condition     = var.log_retention_days == 0
    error_message = "Expected log_retention_days = 0 (never expire) to be accepted."
  }
}

run "byo_sns_topic_skips_create" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name          = "test-backup"
    sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:my-topic"
  }

  assert {
    condition     = var.create_sns_topic == false
    error_message = "Expected create_sns_topic to remain false when sns_topic_arn is supplied."
  }
}

run "vault_with_lock_governance_mode" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-backup"
    vaults = {
      locked = {
        enable_vault_lock              = true
        vault_lock_changeable_for_days = 7
        vault_lock_min_retention_days  = 1
        vault_lock_max_retention_days  = 365
      }
    }
  }

  assert {
    condition     = var.vaults["locked"].enable_vault_lock == true
    error_message = "Expected enable_vault_lock to be accepted as true."
  }
}
