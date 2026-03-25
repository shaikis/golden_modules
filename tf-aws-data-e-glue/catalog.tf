# ---------------------------------------------------------------------------
# Glue Data Catalog — Databases
# ---------------------------------------------------------------------------

resource "aws_glue_catalog_database" "this" {
  for_each = var.create_catalog_databases ? var.catalog_databases : {}

  name         = "${var.name_prefix}${each.key}"
  description  = each.value.description
  location_uri = each.value.location_uri
  parameters   = each.value.parameters != null ? each.value.parameters : {}

  dynamic "target_database" {
    for_each = each.value.target_database != null ? [each.value.target_database] : []
    content {
      catalog_id    = target_database.value.catalog_id
      database_name = target_database.value.database_name
      region        = target_database.value.region
    }
  }

  dynamic "create_table_default_permission" {
    for_each = each.value.create_table_default_permissions != null ? each.value.create_table_default_permissions : []
    content {
      permissions = create_table_default_permission.value.permissions
      principal {
        data_lake_principal_identifier = create_table_default_permission.value.principal.data_lake_principal_identifier
      }
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}${each.key}" })
}

# ---------------------------------------------------------------------------
# Glue Data Catalog — Tables
# ---------------------------------------------------------------------------

resource "aws_glue_catalog_table" "this" {
  for_each = var.catalog_tables

  name          = split("/", each.key)[1]
  database_name = each.value.database_name
  description   = each.value.description
  table_type    = each.value.table_type
  owner         = each.value.owner
  parameters    = each.value.parameters != null ? each.value.parameters : {}

  dynamic "partition_keys" {
    for_each = each.value.partition_keys != null ? each.value.partition_keys : []
    content {
      name    = partition_keys.value.name
      type    = partition_keys.value.type
      comment = partition_keys.value.comment
    }
  }

  dynamic "storage_descriptor" {
    for_each = each.value.storage_descriptor != null ? [each.value.storage_descriptor] : []
    content {
      location                  = storage_descriptor.value.location
      input_format              = storage_descriptor.value.input_format
      output_format             = storage_descriptor.value.output_format
      compressed                = storage_descriptor.value.compressed
      number_of_buckets         = storage_descriptor.value.number_of_buckets
      stored_as_sub_directories = storage_descriptor.value.stored_as_sub_directories
      parameters                = storage_descriptor.value.parameters != null ? storage_descriptor.value.parameters : {}
      bucket_columns            = storage_descriptor.value.bucket_columns != null ? storage_descriptor.value.bucket_columns : []

      dynamic "columns" {
        for_each = storage_descriptor.value.columns != null ? storage_descriptor.value.columns : []
        content {
          name       = columns.value.name
          type       = columns.value.type
          comment    = columns.value.comment
          parameters = columns.value.parameters != null ? columns.value.parameters : {}
        }
      }

      dynamic "ser_de_info" {
        for_each = storage_descriptor.value.ser_de_info != null ? [storage_descriptor.value.ser_de_info] : []
        content {
          name                  = ser_de_info.value.name
          serialization_library = ser_de_info.value.serialization_library
          parameters            = ser_de_info.value.parameters != null ? ser_de_info.value.parameters : {}
        }
      }

      dynamic "sort_columns" {
        for_each = storage_descriptor.value.sort_columns != null ? storage_descriptor.value.sort_columns : []
        content {
          column     = sort_columns.value.column
          sort_order = sort_columns.value.sort_order
        }
      }

      dynamic "skewed_info" {
        for_each = storage_descriptor.value.skewed_info != null ? [storage_descriptor.value.skewed_info] : []
        content {
          skewed_column_names               = skewed_info.value.skewed_column_names
          skewed_column_value_location_maps = skewed_info.value.skewed_column_value_location_maps
          skewed_column_values              = skewed_info.value.skewed_column_values
        }
      }
    }
  }

  depends_on = [aws_glue_catalog_database.this]
}

# ---------------------------------------------------------------------------
# Glue Data Catalog — Encryption Settings
# ---------------------------------------------------------------------------

resource "aws_glue_data_catalog_encryption_settings" "this" {
  count = var.create_catalog_encryption ? 1 : 0

  data_catalog_encryption_settings {
    connection_password_encryption {
      aws_kms_key_id                       = var.catalog_connection_password_encryption_kms_key_id
      return_connection_password_encrypted = var.catalog_connection_password_encryption_kms_key_id != null ? true : false
    }

    encryption_at_rest {
      catalog_encryption_mode = "SSE-KMS"
      sse_aws_kms_key_id      = var.catalog_encryption_kms_key_id
    }
  }
}
