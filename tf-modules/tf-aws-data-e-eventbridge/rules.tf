locals {
  # Resolve event bus name: null key means default bus, otherwise look up custom bus ARN
  rule_event_bus_names = {
    for k, r in var.rules :
    k => r.event_bus_key == null ? "default" : try(aws_cloudwatch_event_bus.this[r.event_bus_key].name, r.event_bus_key)
  }
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each = var.rules

  name                = each.key
  description         = each.value.description
  event_bus_name      = local.rule_event_bus_names[each.key]
  event_pattern       = each.value.event_pattern
  schedule_expression = each.value.schedule_expression
  state               = each.value.state

  tags = merge(var.tags, each.value.tags)

  depends_on = [aws_cloudwatch_event_bus.this]
}
