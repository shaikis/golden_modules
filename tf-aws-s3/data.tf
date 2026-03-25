data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# Bucket Policy Documents
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
