# ---------------------------------------------------------------------------
# Glue Schema Registry
# ---------------------------------------------------------------------------

resource "aws_glue_registry" "this" {
  for_each = var.create_schema_registries ? var.schema_registries : {}

  registry_name = "${var.name_prefix}${each.key}"
  description   = each.value.description

  tags = merge(var.tags, each.value.tags, { Name = "${var.name_prefix}${each.key}" })
}

# ---------------------------------------------------------------------------
# Glue Schemas (one per registry entry)
# ---------------------------------------------------------------------------

# Flatten the nested map: schema_registries[registry_key].schemas[schema_key]
# into a single map keyed by "<registry_key>/<schema_key>".
# Only populated when create_schema_registries = true.
locals {
  all_schemas = var.create_schema_registries ? merge([
    for registry_key, registry_val in var.schema_registries : {
      for schema_key, schema_val in(registry_val.schemas != null ? registry_val.schemas : {}) :
      "${registry_key}/${schema_key}" => merge(schema_val, { registry_key = registry_key })
    }
  ]...) : {}
}

resource "aws_glue_schema" "this" {
  for_each = local.all_schemas

  schema_name       = each.value.schema_name
  registry_arn      = aws_glue_registry.this[each.value.registry_key].arn
  data_format       = each.value.data_format
  compatibility     = each.value.compatibility != null ? each.value.compatibility : "BACKWARD"
  description       = each.value.description
  schema_definition = each.value.schema_definition

  tags = merge(
    var.tags,
    each.value.tags != null ? each.value.tags : {},
    { Name = each.value.schema_name }
  )

  depends_on = [aws_glue_registry.this]
}
