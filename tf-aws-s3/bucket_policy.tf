# ---------------------------------------------------------------------------
# Bucket Policy
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "this" {
  count  = var.attach_deny_insecure_transport_policy || var.attach_require_latest_tls_policy || var.bucket_policy != "" ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.combined.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}
