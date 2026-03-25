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
