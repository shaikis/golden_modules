# Integration tests — tf-aws-backup basic
# command = apply: REAL AWS resources are created, then destroyed.
# Backup vaults are low-cost but require valid AWS credentials.
#
# Prerequisites:
#   export AWS_ACCESS_KEY_ID="..."
#   export AWS_SECRET_ACCESS_KEY="..."
#   export AWS_DEFAULT_REGION="us-east-1"

# SKIP_IN_CI
run "create_single_vault" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name        = "tftest-backup"
    environment = "test"
    tags = {
      Environment = "test"
      ManagedBy   = "terraform-test"
    }
    vaults = {
      primary = {
        force_destroy = true
      }
    }
    create_iam_role = true
  }

  assert {
    condition     = length(var.vaults) == 1
    error_message = "Expected exactly one backup vault to be configured."
  }
}

# SKIP_IN_CI
run "vault_with_notifications" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name        = "tftest-backup-sns"
    environment = "test"
    tags = {
      Environment = "test"
    }
    vaults = {
      notified = {
        force_destroy = true
        notification_events = [
          "BACKUP_JOB_STARTED",
          "BACKUP_JOB_COMPLETED",
          "BACKUP_JOB_FAILED",
        ]
      }
    }
    create_iam_role = true
  }

  assert {
    condition     = length(var.vaults["notified"].notification_events) == 3
    error_message = "Expected three notification events to be configured on the vault."
  }
}
