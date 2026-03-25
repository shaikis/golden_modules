data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_event_bus" "this" {
  for_each = var.create_custom_buses ? var.event_buses : {}

  name              = each.key
  event_source_name = each.value.event_source_name

  kms_key_identifier = coalesce(each.value.kms_key_identifier, var.kms_key_arn)

  tags = merge(var.tags, each.value.tags)
}
