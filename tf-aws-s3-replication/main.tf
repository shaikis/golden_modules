data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# Source Bucket
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "source" {
  bucket = local.name
  tags   = merge(local.tags, { BucketType = "source" })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

resource "aws_s3_bucket_ownership_controls" "source" {
  bucket = aws_s3_bucket.source.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_public_access_block" "source" {
  bucket                  = aws_s3_bucket.source.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.id
  versioning_configuration {
    status     = var.enable_versioning ? "Enabled" : "Suspended"
    mfa_delete = var.enable_mfa_delete ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "source" {
  bucket = aws_s3_bucket.source.id
  rule {
    bucket_key_enabled = var.source_kms_key_id != null ? true : false
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.source_kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.source_kms_key_id
    }
  }
}

resource "aws_s3_bucket_logging" "source" {
  count         = var.enable_access_logging && var.access_log_bucket_id != "" ? 1 : 0
  bucket        = aws_s3_bucket.source.id
  target_bucket = var.access_log_bucket_id
  target_prefix = "${local.name}/access-logs/"
}

resource "aws_s3_bucket_object_lock_configuration" "source" {
  count  = var.object_lock_enabled ? 1 : 0
  bucket = aws_s3_bucket.source.id
  rule {
    default_retention {
      mode  = var.object_lock_mode
      days  = var.object_lock_days
      years = var.object_lock_years
    }
  }
  depends_on = [aws_s3_bucket_versioning.source]
}

resource "aws_s3_bucket_lifecycle_configuration" "source" {
  count  = length(var.source_lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.source.id

  dynamic "rule" {
    for_each = var.source_lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [rule.value.expiration_days] : []
        content { days = expiration.value }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration_days != null ? [rule.value.noncurrent_version_expiration_days] : []
        content { noncurrent_days = noncurrent_version_expiration.value }
      }

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.source]
}

# ---------------------------------------------------------------------------
# Source Bucket Policy
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "source_policy" {
  dynamic "statement" {
    for_each = var.attach_deny_insecure_transport ? [1] : []
    content {
      sid    = "DenyInsecureTransport"
      effect = "Deny"
      principals {
        type        = "*"
        identifiers = ["*"]
      }
      actions   = ["s3:*"]
      resources = [aws_s3_bucket.source.arn, "${aws_s3_bucket.source.arn}/*"]
      condition {
        test     = "Bool"
        variable = "aws:SecureTransport"
        values   = ["false"]
      }
    }
  }
  dynamic "statement" {
    for_each = var.attach_require_tls12 ? [1] : []
    content {
      sid    = "RequireTLS12"
      effect = "Deny"
      principals {
        type        = "*"
        identifiers = ["*"]
      }
      actions   = ["s3:*"]
      resources = [aws_s3_bucket.source.arn, "${aws_s3_bucket.source.arn}/*"]
      condition {
        test     = "NumericLessThan"
        variable = "s3:TlsVersion"
        values   = ["1.2"]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "source" {
  bucket = aws_s3_bucket.source.id
  policy = data.aws_iam_policy_document.source_policy.json
  depends_on = [aws_s3_bucket_public_access_block.source]
}

# ---------------------------------------------------------------------------
# Replication IAM Role
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "replication_assume" {
  count = (var.enable_srr || var.enable_crr) && var.replication_role_arn == null ? 1 : 0
  statement {
    effect    = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "replication" {
  count              = (var.enable_srr || var.enable_crr) && var.replication_role_arn == null ? 1 : 0
  name               = "${local.name}-s3-replication"
  assume_role_policy = data.aws_iam_policy_document.replication_assume[0].json
  tags               = local.tags
}

data "aws_iam_policy_document" "replication_policy" {
  count = (var.enable_srr || var.enable_crr) && var.replication_role_arn == null ? 1 : 0

  statement {
    sid    = "SourceBucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.source.arn]
  }

  statement {
    sid    = "SourceObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${aws_s3_bucket.source.arn}/*"]
  }

  statement {
    sid    = "DestinationBucketAccess"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]
    resources = compact(concat(
      var.enable_srr ? ["arn:aws:s3:::${local.srr_bucket_computed_name}/*"] : [],
      [for d in var.crr_destinations : "${d.bucket_arn}/*"],
    ))
  }

  dynamic "statement" {
    for_each = var.source_kms_key_id != null ? [1] : []
    content {
      sid     = "SourceKMSDecrypt"
      effect  = "Allow"
      actions = ["kms:Decrypt"]
      resources = [var.source_kms_key_id]
    }
  }

  dynamic "statement" {
    for_each = concat(
      var.srr_kms_key_id != null ? [var.srr_kms_key_id] : [],
      [for d in var.crr_destinations : d.kms_key_id if d.kms_key_id != null]
    )
    content {
      sid     = "DestKMSEncrypt-${sha1(statement.value)}"
      effect  = "Allow"
      actions = ["kms:Encrypt", "kms:GenerateDataKey"]
      resources = [statement.value]
    }
  }
}

resource "aws_iam_role_policy" "replication" {
  count  = (var.enable_srr || var.enable_crr) && var.replication_role_arn == null ? 1 : 0
  name   = "${local.name}-s3-replication-policy"
  role   = aws_iam_role.replication[0].id
  policy = data.aws_iam_policy_document.replication_policy[0].json
}

# ---------------------------------------------------------------------------
# SRR – Same-Region Replica (Backup) Bucket
# ---------------------------------------------------------------------------
locals {
  srr_bucket_computed_name = var.srr_bucket_name != "" ? var.srr_bucket_name : "${local.name}-backup"
}

resource "aws_s3_bucket" "srr" {
  count  = var.enable_srr ? 1 : 0
  bucket = local.srr_bucket_computed_name
  tags   = merge(local.tags, { BucketType = "srr-replica" })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

resource "aws_s3_bucket_ownership_controls" "srr" {
  count  = var.enable_srr ? 1 : 0
  bucket = aws_s3_bucket.srr[0].id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_public_access_block" "srr" {
  count                   = var.enable_srr ? 1 : 0
  bucket                  = aws_s3_bucket.srr[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "srr" {
  count  = var.enable_srr ? 1 : 0
  bucket = aws_s3_bucket.srr[0].id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "srr" {
  count  = var.enable_srr ? 1 : 0
  bucket = aws_s3_bucket.srr[0].id
  rule {
    bucket_key_enabled = var.srr_kms_key_id != null ? true : false
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.srr_kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.srr_kms_key_id
    }
  }
}

# ---------------------------------------------------------------------------
# CRR – Cross-Region Replica Buckets (pre-existing, passed via variable)
# ---------------------------------------------------------------------------
# NOTE: Destination buckets for CRR are usually pre-created in each region
# using the tf-aws-s3 module with provider aliases. This module manages
# the replication CONFIGURATION on the source bucket only.

# ---------------------------------------------------------------------------
# Combined Replication Configuration
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_replication_configuration" "this" {
  count  = var.enable_srr || var.enable_crr ? 1 : 0
  bucket = aws_s3_bucket.source.id
  role   = var.replication_role_arn != null ? var.replication_role_arn : aws_iam_role.replication[0].arn

  # SRR rule
  dynamic "rule" {
    for_each = var.enable_srr ? [1] : []
    content {
      id     = "srr-backup"
      status = "Enabled"

      filter {}

      delete_marker_replication { status = "Enabled" }

      destination {
        bucket        = aws_s3_bucket.srr[0].arn
        storage_class = var.srr_storage_class

        dynamic "encryption_configuration" {
          for_each = var.srr_kms_key_id != null ? [1] : []
          content { replica_kms_key_id = var.srr_kms_key_id }
        }
      }
    }
  }

  # CRR rules — one per destination
  dynamic "rule" {
    for_each = var.crr_destinations
    content {
      id     = rule.key
      status = "Enabled"

      dynamic "filter" {
        for_each = rule.value.prefix_filter != null ? [rule.value.prefix_filter] : []
        content { prefix = filter.value }
      }

      dynamic "filter" {
        for_each = rule.value.prefix_filter == null ? [1] : []
        content {}
      }

      dynamic "delete_marker_replication" {
        for_each = rule.value.delete_marker_replication ? [1] : []
        content { status = "Enabled" }
      }

      destination {
        bucket        = rule.value.bucket_arn
        storage_class = rule.value.storage_class
        account       = rule.value.account

        dynamic "encryption_configuration" {
          for_each = rule.value.kms_key_id != null ? [1] : []
          content { replica_kms_key_id = rule.value.kms_key_id }
        }

        dynamic "access_control_translation" {
          for_each = rule.value.account != null ? [1] : []
          content { owner = "Destination" }
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.source]
}

# ---------------------------------------------------------------------------
# AWS Backup – S3 Backup Plan
# ---------------------------------------------------------------------------
resource "aws_backup_vault" "this" {
  count       = var.enable_aws_backup ? 1 : 0
  name        = "${local.name}-backup-vault"
  kms_key_arn = var.backup_kms_key_arn
  tags        = local.tags
}

resource "aws_backup_plan" "this" {
  count = var.enable_aws_backup ? 1 : 0
  name  = "${local.name}-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.this[0].name
    schedule          = var.backup_schedule

    lifecycle {
      delete_after = var.backup_retention_days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.this[0].arn
      lifecycle { delete_after = var.backup_retention_days }
    }
  }

  tags = local.tags
}

resource "aws_backup_selection" "this" {
  count        = var.enable_aws_backup ? 1 : 0
  name         = "${local.name}-backup-selection"
  plan_id      = aws_backup_plan.this[0].id
  iam_role_arn = aws_iam_role.backup[0].arn

  resources = [aws_s3_bucket.source.arn]
}

resource "aws_iam_role" "backup" {
  count = var.enable_aws_backup ? 1 : 0
  name  = "${local.name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "backup_s3_backup" {
  count      = var.enable_aws_backup ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForS3Backup"
}

resource "aws_iam_role_policy_attachment" "backup_s3_restore" {
  count      = var.enable_aws_backup ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForS3Restore"
}
