# ── Step Functions Activities ─────────────────────────────────────────────────
# Gated by create_activities = true

resource "aws_sfn_activity" "this" {
  for_each = var.create_activities ? var.activities : {}

  name = "${var.name_prefix}${each.key}"
  tags = merge(var.tags, each.value.tags)
}
