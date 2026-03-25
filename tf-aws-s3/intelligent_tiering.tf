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
