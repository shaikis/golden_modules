# ---------------------------------------------------------------------------
# Rekognition Face Collections
# Controlled by: create_collections = true
# ---------------------------------------------------------------------------

resource "aws_rekognition_collection" "this" {
  for_each = var.create_collections ? var.collections : {}

  collection_id = "${local.name_prefix}${each.key}"

  tags = merge(local.tags, each.value.tags)
}
