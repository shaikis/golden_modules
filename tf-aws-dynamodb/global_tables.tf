# ---------------------------------------------------------------------------
# DynamoDB Global Tables (multi-region replication)
# NOTE: lifecycle prevent_destroy = true cannot be applied conditionally in
#       Terraform. For production global tables, uncomment the lifecycle block
#       below or manage via a separate root module with the constraint hard-coded.
# ---------------------------------------------------------------------------

locals {
  global_table_attributes = {
    for table_key, table in var.global_tables : table_key => distinct(concat(
      [{ name = table.hash_key, type = table.hash_key_type }],
      table.range_key != null ? [{ name = table.range_key, type = table.range_key_type }] : [],
      flatten([
        for gsi in table.global_secondary_indexes : concat(
          [{ name = gsi.hash_key, type = gsi.hash_key_type }],
          gsi.range_key != null ? [{ name = gsi.range_key, type = gsi.range_key_type }] : []
        )
      ])
    ))
  }

  global_table_attributes_deduped = {
    for table_key, attrs in local.global_table_attributes : table_key => {
      for attr in attrs : attr.name => attr.type...
    }
  }
}

resource "aws_dynamodb_table" "global" {
  for_each = var.global_tables

  name         = "${var.name_prefix}-${each.key}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = each.value.hash_key
  range_key    = each.value.range_key

  # Streams must be enabled for Global Tables
  stream_enabled   = true
  stream_view_type = each.value.stream_view_type

  table_class = "STANDARD"

  deletion_protection_enabled = each.value.deletion_protection

  dynamic "attribute" {
    for_each = local.global_table_attributes_deduped[each.key]
    content {
      name = attribute.key
      type = attribute.value[0]
    }
  }

  point_in_time_recovery {
    enabled = each.value.point_in_time_recovery
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = each.value.kms_key_arn
  }

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
    }
  }

  dynamic "replica" {
    for_each = { for r in each.value.replicas : r.region_name => r }
    content {
      region_name            = replica.value.region_name
      kms_key_arn            = replica.value.kms_key_arn
      point_in_time_recovery = replica.value.point_in_time_recovery
      propagate_tags         = replica.value.propagate_tags
    }
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name      = "${var.name_prefix}-${each.key}"
      ManagedBy = "terraform"
      backup    = "true"
    }
  )

  # Uncomment to prevent accidental deletion of global tables in production:
  # lifecycle {
  #   prevent_destroy = true
  # }
}
