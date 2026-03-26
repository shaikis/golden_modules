# ---------------------------------------------------------------------------
# Rekognition Custom Labels Projects
# Controlled by: create_custom_labels_projects = true
# ---------------------------------------------------------------------------

resource "aws_rekognition_project" "this" {
  for_each = var.create_custom_labels_projects ? var.custom_labels_projects : {}

  name = "${local.name_prefix}${each.key}"

  tags = merge(local.tags, each.value.tags)
}
