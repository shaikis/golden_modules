resource "aws_cloudwatch_event_archive" "this" {
  for_each = var.create_archives ? var.archives : {}

  name             = each.key
  event_source_arn = each.value.event_source_arn
  description      = each.value.description
  retention_days   = each.value.retention_days
  event_pattern    = each.value.event_pattern
}
