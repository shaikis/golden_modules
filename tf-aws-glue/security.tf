# ---------------------------------------------------------------------------
# Glue Security Configurations
# ---------------------------------------------------------------------------

resource "aws_glue_security_configuration" "this" {
  for_each = var.create_security_configurations ? var.security_configurations : {}

  name = "${var.name_prefix}${each.key}"

  encryption_configuration {
    # ---- S3 encryption --------------------------------------------------
    s3_encryption {
      s3_encryption_mode = each.value.s3_encryption_mode != null ? each.value.s3_encryption_mode : "SSE-KMS"
      kms_key_arn        = each.value.s3_kms_key_arn
    }

    # ---- CloudWatch Logs encryption -------------------------------------
    cloudwatch_encryption {
      cloudwatch_encryption_mode = each.value.cloudwatch_encryption_mode != null ? each.value.cloudwatch_encryption_mode : "SSE-KMS"
      kms_key_arn                = each.value.cloudwatch_kms_key_arn
    }

    # ---- Job Bookmarks encryption ---------------------------------------
    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = each.value.bookmark_encryption_mode != null ? each.value.bookmark_encryption_mode : "CSE-KMS"
      kms_key_arn                   = each.value.bookmark_kms_key_arn
    }
  }
}
