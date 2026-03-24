data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# S3 Bucket
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
  bucket        = local.name
  force_destroy = var.force_destroy

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

# ---------------------------------------------------------------------------
# Ownership Controls
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

# ---------------------------------------------------------------------------
# Block Public Access (always enabled by default)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# ---------------------------------------------------------------------------
# Versioning
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status     = var.versioning_enabled ? "Enabled" : "Suspended"
    mfa_delete = var.mfa_delete ? "Enabled" : "Disabled"
  }
}

# ---------------------------------------------------------------------------
# Server-Side Encryption
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    bucket_key_enabled = var.sse_algorithm == "aws:kms" ? var.bucket_key_enabled : null

    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.kms_master_key_id
    }
  }
}

# ---------------------------------------------------------------------------
# Access Logging
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_logging" "this" {
  count = var.enable_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.access_log_bucket
  target_prefix = var.access_log_prefix != "" ? var.access_log_prefix : "${local.name}/"
}

# ---------------------------------------------------------------------------
# Lifecycle Rules
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      dynamic "filter" {
        for_each = rule.value.prefix != null || length(rule.value.tags) > 0 ? [1] : []
        content {
          prefix = rule.value.prefix

          dynamic "tag" {
            for_each = rule.value.tags
            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days                         = expiration.value.days
          date                         = expiration.value.date
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days           = noncurrent_version_expiration.value.noncurrent_days
          newer_noncurrent_versions = noncurrent_version_expiration.value.newer_noncurrent_versions
        }
      }

      dynamic "transition" {
        for_each = rule.value.transition
        content {
          days          = transition.value.days
          date          = transition.value.date
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition
        content {
          noncurrent_days           = noncurrent_version_transition.value.noncurrent_days
          newer_noncurrent_versions = noncurrent_version_transition.value.newer_noncurrent_versions
          storage_class             = noncurrent_version_transition.value.storage_class
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

# ---------------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_cors_configuration" "this" {
  count  = length(var.cors_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# ---------------------------------------------------------------------------
# Static Website
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_website_configuration" "this" {
  count  = var.website != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "index_document" {
    for_each = var.website.index_document != null ? [1] : []
    content {
      suffix = var.website.index_document
    }
  }

  dynamic "error_document" {
    for_each = var.website.error_document != null ? [1] : []
    content {
      key = var.website.error_document
    }
  }

  dynamic "redirect_all_requests_to" {
    for_each = var.website.redirect_all_requests_to != null ? [1] : []
    content {
      host_name = var.website.redirect_all_requests_to
    }
  }
}

# ---------------------------------------------------------------------------
# Object Lock
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_object_lock_configuration" "this" {
  count  = var.object_lock_enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    default_retention {
      mode  = var.object_lock_mode
      days  = var.object_lock_days
      years = var.object_lock_years
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

# ---------------------------------------------------------------------------
# Bucket Policy
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "combined" {
  source_policy_documents = compact([
    var.attach_deny_insecure_transport_policy ? data.aws_iam_policy_document.deny_insecure_transport[0].json : "",
    var.attach_require_latest_tls_policy ? data.aws_iam_policy_document.require_latest_tls[0].json : "",
    var.bucket_policy,
  ])
}

data "aws_iam_policy_document" "deny_insecure_transport" {
  count = var.attach_deny_insecure_transport_policy ? 1 : 0

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "require_latest_tls" {
  count = var.attach_require_latest_tls_policy ? 1 : 0

  statement {
    sid    = "RequireTLS12"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count  = var.attach_deny_insecure_transport_policy || var.attach_require_latest_tls_policy || var.bucket_policy != "" ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.combined.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}

# ---------------------------------------------------------------------------
# Replication
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_replication_configuration" "this" {
  count  = var.replication_configuration != null ? 1 : 0
  bucket = aws_s3_bucket.this.id
  role   = var.replication_configuration.role

  dynamic "rule" {
    for_each = var.replication_configuration.rules

    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "filter" {
        for_each = rule.value.prefix != null ? [rule.value.prefix] : []
        content {
          prefix = filter.value
        }
      }

      destination {
        bucket        = rule.value.destination_bucket
        storage_class = rule.value.destination_storage_class

        dynamic "encryption_configuration" {
          for_each = rule.value.replica_kms_key_id != null ? [1] : []
          content {
            replica_kms_key_id = rule.value.replica_kms_key_id
          }
        }
      }

      dynamic "delete_marker_replication" {
        for_each = rule.value.delete_marker_replication ? [1] : []
        content { status = "Enabled" }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

# ---------------------------------------------------------------------------
# Notifications
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_notification" "this" {
  count  = var.notifications != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "lambda_function" {
    for_each = try(var.notifications.lambda_functions, [])
    content {
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.filter_prefix
      filter_suffix       = lambda_function.value.filter_suffix
    }
  }

  dynamic "queue" {
    for_each = try(var.notifications.sqs_queues, [])
    content {
      queue_arn     = queue.value.queue_arn
      events        = queue.value.events
      filter_prefix = queue.value.filter_prefix
      filter_suffix = queue.value.filter_suffix
    }
  }

  dynamic "topic" {
    for_each = try(var.notifications.sns_topics, [])
    content {
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = topic.value.filter_prefix
      filter_suffix = topic.value.filter_suffix
    }
  }
}

# ---------------------------------------------------------------------------
# Intelligent-Tiering
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_intelligent_tiering_configuration" "this" {
  for_each = { for cfg in var.intelligent_tiering_configurations : cfg.name => cfg }

  bucket = aws_s3_bucket.this.id
  name   = each.key
  status = each.value.status

  dynamic "filter" {
    for_each = each.value.filter != null ? [each.value.filter] : []
    content {
      prefix = filter.value.prefix
      dynamic "tag" {
        for_each = filter.value.tags
        content { key = tag.key; value = tag.value }
      }
    }
  }

  dynamic "tiering" {
    for_each = each.value.tierings
    content {
      access_tier = tiering.value.access_tier
      days        = tiering.value.days
    }
  }
}
