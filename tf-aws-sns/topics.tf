resource "aws_sns_topic" "this" {
  name                        = var.fifo_topic ? "${local.name}.fifo" : local.name
  display_name                = var.display_name
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic && var.content_based_deduplication ? true : false
  kms_master_key_id           = var.kms_master_key_id
  delivery_policy             = var.delivery_policy

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

resource "aws_sns_topic_policy" "this" {
  count  = var.topic_policy != "" ? 1 : 0
  arn    = aws_sns_topic.this.arn
  policy = var.topic_policy
}

resource "aws_sns_topic_subscription" "this" {
  for_each = var.subscriptions

  topic_arn                       = aws_sns_topic.this.arn
  protocol                        = each.value.protocol
  endpoint                        = each.value.endpoint
  raw_message_delivery            = each.value.raw_message_delivery
  filter_policy                   = each.value.filter_policy
  filter_policy_scope             = each.value.filter_policy_scope
  redrive_policy                  = each.value.redrive_policy
  confirmation_timeout_in_minutes = each.value.confirmation_timeout_in_minutes
}
