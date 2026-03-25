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
