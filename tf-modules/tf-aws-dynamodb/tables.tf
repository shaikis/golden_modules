# ---------------------------------------------------------------------------
# DynamoDB Tables
# ---------------------------------------------------------------------------

locals {
  # Flatten all unique attribute definitions needed across keys and indexes
  # per table so we can build the attribute blocks without duplicates.
  table_attributes = {
    for table_key, table in var.tables : table_key => distinct(concat(
      # Primary key attributes
      [{ name = table.hash_key, type = table.hash_key_type }],
      table.range_key != null ? [{ name = table.range_key, type = table.range_key_type }] : [],
      # GSI attributes
      flatten([
        for gsi in table.global_secondary_indexes : concat(
          [{ name = gsi.hash_key, type = gsi.hash_key_type }],
          gsi.range_key != null ? [{ name = gsi.range_key, type = gsi.range_key_type }] : []
        )
      ]),
      # LSI attributes
      flatten([
        for lsi in table.local_secondary_indexes : [
          { name = lsi.range_key, type = lsi.range_key_type }
        ]
      ])
    ))
  }

  # Deduplicate by attribute name (keep first occurrence)
  table_attributes_deduped = {
    for table_key, attrs in local.table_attributes : table_key => {
      for attr in attrs : attr.name => attr.type...
    }
  }
}

resource "aws_dynamodb_table" "this" {
  for_each = var.tables

  name         = "${var.name_prefix}-${each.key}"
  billing_mode = each.value.billing_mode
  hash_key     = each.value.hash_key
  range_key    = each.value.range_key

  # Capacity — only meaningful for PROVISIONED tables
  read_capacity  = each.value.billing_mode == "PROVISIONED" ? each.value.read_capacity : null
  write_capacity = each.value.billing_mode == "PROVISIONED" ? each.value.write_capacity : null

  table_class = each.value.table_class

  deletion_protection_enabled = each.value.deletion_protection

  # Streams
  stream_enabled   = each.value.stream_enabled
  stream_view_type = each.value.stream_enabled ? each.value.stream_view_type : null

  # Attribute definitions (deduplicated)
  dynamic "attribute" {
    for_each = local.table_attributes_deduped[each.key]
    content {
      name = attribute.key
      type = attribute.value[0]
    }
  }

  # TTL
  dynamic "ttl" {
    for_each = each.value.ttl_attribute != null ? [each.value.ttl_attribute] : []
    content {
      attribute_name = ttl.value
      enabled        = true
    }
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = each.value.point_in_time_recovery
  }

  # Server-side encryption
  server_side_encryption {
    enabled           = true
    kms_master_key_id = each.value.kms_key_arn
  }

  # Global Secondary Indexes
  dynamic "global_secondary_index" {
    for_each = { for gsi in each.value.global_secondary_indexes : gsi.name => gsi }
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = global_secondary_index.value.range_key
      projection_type = global_secondary_index.value.projection_type

      non_key_attributes = (
        global_secondary_index.value.projection_type == "INCLUDE"
        ? global_secondary_index.value.non_key_attributes
        : null
      )

      read_capacity = (
        each.value.billing_mode == "PROVISIONED"
        ? global_secondary_index.value.read_capacity
        : null
      )
      write_capacity = (
        each.value.billing_mode == "PROVISIONED"
        ? global_secondary_index.value.write_capacity
        : null
      )
    }
  }

  # Local Secondary Indexes
  dynamic "local_secondary_index" {
    for_each = { for lsi in each.value.local_secondary_indexes : lsi.name => lsi }
    content {
      name            = local_secondary_index.value.name
      range_key       = local_secondary_index.value.range_key
      projection_type = local_secondary_index.value.projection_type

      non_key_attributes = (
        local_secondary_index.value.projection_type == "INCLUDE"
        ? local_secondary_index.value.non_key_attributes
        : null
      )
    }
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name      = "${var.name_prefix}-${each.key}"
      ManagedBy = "terraform"
      backup    = each.value.backup_enabled ? "true" : "false"
    }
  )
}
