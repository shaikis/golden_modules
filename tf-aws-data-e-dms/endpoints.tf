resource "aws_dms_endpoint" "this" {
  for_each = var.endpoints

  endpoint_id   = each.key
  endpoint_type = lower(each.value.endpoint_type)
  engine_name   = each.value.engine_name

  server_name   = each.value.server_name
  port          = each.value.port
  database_name = each.value.database_name
  username      = each.value.secrets_manager_arn != null ? null : each.value.username
  password      = each.value.secrets_manager_arn != null ? null : each.value.password

  secrets_manager_arn             = each.value.secrets_manager_arn
  secrets_manager_access_role_arn = each.value.secrets_manager_access_role_arn

  ssl_mode        = each.value.ssl_mode
  certificate_arn = each.value.certificate_arn

  extra_connection_attributes = each.value.extra_connection_attributes

  dynamic "s3_settings" {
    for_each = each.value.s3_settings != null ? [each.value.s3_settings] : []
    content {
      bucket_name                      = s3_settings.value.bucket_name
      bucket_folder                    = s3_settings.value.bucket_folder
      compression_type                 = s3_settings.value.compression_type
      data_format                      = s3_settings.value.data_format
      parquet_version                  = s3_settings.value.data_format == "parquet" ? s3_settings.value.parquet_version : null
      enable_statistics                = s3_settings.value.enable_statistics
      include_op_for_full_load         = s3_settings.value.include_op_for_full_load
      timestamp_column_name            = s3_settings.value.timestamp_column_name
      service_access_role_arn          = s3_settings.value.service_access_role_arn
      cdc_inserts_only                 = s3_settings.value.cdc_inserts_only
      cdc_inserts_and_updates          = s3_settings.value.cdc_inserts_and_updates
      encoding_type                    = s3_settings.value.encoding_type
      dict_page_size_limit             = s3_settings.value.dict_page_size_limit
      row_group_length                 = s3_settings.value.row_group_length
      data_page_size                   = s3_settings.value.data_page_size
      parquet_timestamp_in_millisecond = s3_settings.value.parquet_timestamp_in_millisecond
      use_csv_no_sup_value             = s3_settings.value.use_csv_no_sup_value
    }
  }

  dynamic "kinesis_settings" {
    for_each = each.value.kinesis_settings != null ? [each.value.kinesis_settings] : []
    content {
      stream_arn                     = kinesis_settings.value.stream_arn
      message_format                 = kinesis_settings.value.message_format
      service_access_role_arn        = kinesis_settings.value.service_access_role_arn
      include_table_alter_operations = kinesis_settings.value.include_table_alter_operations
      include_control_details        = kinesis_settings.value.include_control_details
      include_null_and_empty         = kinesis_settings.value.include_null_and_empty
      include_partition_value        = kinesis_settings.value.include_partition_value
      partition_include_schema_table = kinesis_settings.value.partition_include_schema_table
    }
  }

  dynamic "kafka_settings" {
    for_each = each.value.kafka_settings != null ? [each.value.kafka_settings] : []
    content {
      broker                         = kafka_settings.value.broker
      topic                          = kafka_settings.value.topic
      message_format                 = kafka_settings.value.message_format
      include_table_alter_operations = kafka_settings.value.include_table_alter_operations
      include_control_details        = kafka_settings.value.include_control_details
      include_null_and_empty         = kafka_settings.value.include_null_and_empty
      include_partition_value        = kafka_settings.value.include_partition_value
      partition_include_schema_table = kafka_settings.value.partition_include_schema_table
      ssl_client_certificate_arn     = kafka_settings.value.ssl_client_certificate_arn
      ssl_client_key_arn             = kafka_settings.value.ssl_client_key_arn
      ssl_ca_certificate_arn         = kafka_settings.value.ssl_ca_certificate_arn
      security_protocol              = kafka_settings.value.security_protocol
      sasl_username                  = kafka_settings.value.sasl_username
      sasl_password                  = kafka_settings.value.sasl_password
    }
  }

  dynamic "redshift_settings" {
    for_each = each.value.redshift_settings != null ? [each.value.redshift_settings] : []
    content {
      bucket_name                       = redshift_settings.value.bucket_name
      bucket_folder                     = redshift_settings.value.bucket_folder
      service_access_role_arn           = redshift_settings.value.service_access_role_arn
      server_side_encryption_kms_key_id = redshift_settings.value.server_side_encryption_kms_key_id
      encryption_mode                   = redshift_settings.value.encryption_mode
      accept_any_date                   = redshift_settings.value.accept_any_date
      date_format                       = redshift_settings.value.date_format
      time_format                       = redshift_settings.value.time_format
      empty_as_null                     = redshift_settings.value.empty_as_null
      trim_blanks                       = redshift_settings.value.trim_blanks
      truncate_columns                  = redshift_settings.value.truncate_columns
    }
  }

  dynamic "mongodb_settings" {
    for_each = each.value.mongodb_settings != null ? [each.value.mongodb_settings] : []
    content {
      auth_mechanism      = mongodb_settings.value.auth_mechanism
      auth_source         = mongodb_settings.value.auth_source
      auth_type           = mongodb_settings.value.auth_type
      docs_to_investigate = tostring(mongodb_settings.value.docs_to_investigate)
      extract_doc_id      = tostring(mongodb_settings.value.extract_doc_id)
      nesting_level       = mongodb_settings.value.nesting_level
    }
  }

  tags = merge(var.tags, each.value.tags)
}
