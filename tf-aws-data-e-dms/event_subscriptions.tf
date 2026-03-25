resource "aws_dms_event_subscription" "this" {
  for_each = var.create_event_subscriptions ? var.event_subscriptions : {}

  name             = each.key
  sns_topic_arn    = each.value.sns_topic_arn
  source_type      = each.value.source_type
  source_ids       = each.value.source_ids
  event_categories = each.value.event_categories
  enabled          = each.value.enabled

  tags = merge(var.tags, each.value.tags)
}
