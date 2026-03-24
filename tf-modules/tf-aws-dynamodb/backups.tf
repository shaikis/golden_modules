# ---------------------------------------------------------------------------
# AWS Backup — DynamoDB tables
# ---------------------------------------------------------------------------

locals {
  vault_name = var.backup_vault_name != null ? var.backup_vault_name : "${var.name_prefix}-dynamodb-vault"
}

# ---------------------------------------------------------------------------
# Backup Vault
# ---------------------------------------------------------------------------

resource "aws_backup_vault" "this" {
  count = var.create_backup_plan ? 1 : 0

  name        = local.vault_name
  kms_key_arn = null # uses AWS-managed key; supply var if needed

  tags = merge(var.tags, {
    Name      = local.vault_name
    ManagedBy = "terraform"
  })
}

# WORM lock — compliance mode prevents vault deletion until max_retention_days
resource "aws_backup_vault_lock_configuration" "this" {
  count = var.create_backup_plan && var.backup_vault_lock_min_retention_days > 0 ? 1 : 0

  backup_vault_name  = aws_backup_vault.this[0].name
  min_retention_days = var.backup_vault_lock_min_retention_days
  max_retention_days = var.backup_vault_lock_max_retention_days
}

# ---------------------------------------------------------------------------
# Backup Plan
# ---------------------------------------------------------------------------

resource "aws_backup_plan" "this" {
  count = var.create_backup_plan ? 1 : 0

  name = "${var.name_prefix}-dynamodb-backup-plan"

  # Daily backup — 2 AM UTC, 35-day retention
  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.this[0].name
    schedule          = "cron(0 2 * * ? *)"
    start_window      = 60
    completion_window = 180

    lifecycle {
      delete_after = 35
    }

    dynamic "copy_action" {
      for_each = var.backup_secondary_vault_arn != null ? [var.backup_secondary_vault_arn] : []
      content {
        destination_vault_arn = copy_action.value
        lifecycle {
          delete_after = 35
        }
      }
    }
  }

  # Weekly backup — Sunday 3 AM UTC, 90-day retention
  rule {
    rule_name         = "weekly-backup"
    target_vault_name = aws_backup_vault.this[0].name
    schedule          = "cron(0 3 ? * 1 *)"
    start_window      = 60
    completion_window = 300

    lifecycle {
      delete_after = 90
    }

    dynamic "copy_action" {
      for_each = var.backup_secondary_vault_arn != null ? [var.backup_secondary_vault_arn] : []
      content {
        destination_vault_arn = copy_action.value
        lifecycle {
          delete_after = 90
        }
      }
    }
  }

  # Monthly backup — first of month 4 AM UTC, 365-day retention + cold storage after 90 days
  rule {
    rule_name         = "monthly-backup"
    target_vault_name = aws_backup_vault.this[0].name
    schedule          = "cron(0 4 1 * ? *)"
    start_window      = 60
    completion_window = 480

    lifecycle {
      cold_storage_after = 90
      delete_after       = 365
    }

    dynamic "copy_action" {
      for_each = var.backup_secondary_vault_arn != null ? [var.backup_secondary_vault_arn] : []
      content {
        destination_vault_arn = copy_action.value
        lifecycle {
          cold_storage_after = 90
          delete_after       = 365
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-dynamodb-backup-plan"
    ManagedBy = "terraform"
  })
}

# ---------------------------------------------------------------------------
# IAM Role for AWS Backup
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "backup_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  count = var.create_backup_plan ? 1 : 0

  name               = "${var.name_prefix}-dynamodb-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  count = var.create_backup_plan ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore_policy" {
  count = var.create_backup_plan ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# ---------------------------------------------------------------------------
# Backup Selection — tag-based (backup = "true")
# ---------------------------------------------------------------------------

resource "aws_backup_selection" "this" {
  count = var.create_backup_plan ? 1 : 0

  name         = "${var.name_prefix}-dynamodb-selection"
  iam_role_arn = aws_iam_role.backup[0].arn
  plan_id      = aws_backup_plan.this[0].id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "backup"
    value = "true"
  }
}
