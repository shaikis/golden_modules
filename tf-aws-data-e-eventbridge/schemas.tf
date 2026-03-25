resource "aws_schemas_registry" "this" {
  for_each = var.create_schema_registries ? var.schema_registries : {}

  name        = each.key
  description = each.value.description

  tags = merge(var.tags, each.value.tags)
}

resource "aws_schemas_schema" "this" {
  for_each = var.create_schema_registries ? var.schemas : {}

  name          = each.key
  registry_name = aws_schemas_registry.this[each.value.registry_key].name
  type          = each.value.type
  content       = each.value.content
  description   = each.value.description

  tags = merge(var.tags, each.value.tags)

  depends_on = [aws_schemas_registry.this]
}

resource "aws_schemas_discoverer" "this" {
  for_each = var.create_schema_registries ? var.schema_discoverers : {}

  source_arn  = each.value.event_bus_key != null ? aws_cloudwatch_event_bus.this[each.value.event_bus_key].arn : "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:event-bus/default"
  description = each.value.description

  tags = merge(var.tags, each.value.tags)

  depends_on = [aws_cloudwatch_event_bus.this]
}
