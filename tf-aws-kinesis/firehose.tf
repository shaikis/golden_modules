# ---------------------------------------------------------------------------
# Kinesis Firehose Delivery Streams
# ---------------------------------------------------------------------------

locals {
  # Split firehose streams by destination type for cleaner for_each logic.
  # All maps are empty when create_firehose_streams = false.
  firehose_s3 = var.create_firehose_streams ? {
    for k, v in var.firehose_streams : k => v
    if v.destination == "s3"
  } : {}
  firehose_redshift = var.create_firehose_streams ? {
    for k, v in var.firehose_streams : k => v
    if v.destination == "redshift"
  } : {}
  firehose_opensearch = var.create_firehose_streams ? {
    for k, v in var.firehose_streams : k => v
    if v.destination == "opensearch"
  } : {}
  firehose_splunk = var.create_firehose_streams ? {
    for k, v in var.firehose_streams : k => v
    if v.destination == "splunk"
  } : {}
  firehose_http = var.create_firehose_streams ? {
    for k, v in var.firehose_streams : k => v
    if v.destination == "http_endpoint"
  } : {}
}

# ---------------------------------------------------------------------------
# S3 destination
# ---------------------------------------------------------------------------

resource "aws_kinesis_firehose_delivery_stream" "s3" {
  for_each = local.firehose_s3

  name        = "${var.name_prefix}${each.key}"
  destination = "extended_s3"

  dynamic "kinesis_source_configuration" {
    for_each = each.value.source_stream_key != null ? [1] : []
    content {
      kinesis_stream_arn = aws_kinesis_stream.this[each.value.source_stream_key].arn
      role_arn           = var.create_iam_roles && var.create_firehose_role ? aws_iam_role.firehose[0].arn : null
    }
  }

  extended_s3_configuration {
    role_arn            = var.create_iam_roles && var.create_firehose_role ? aws_iam_role.firehose[0].arn : null
    bucket_arn          = each.value.s3_config.bucket_arn
    prefix              = each.value.s3_config.prefix
    error_output_prefix = each.value.s3_config.error_output_prefix
    buffering_size      = each.value.s3_config.buffering_size
    buffering_interval  = each.value.s3_config.buffering_interval
    compression_format  = each.value.s3_config.compression_format
    kms_key_arn         = each.value.s3_config.kms_key_arn

    dynamic "cloudwatch_logging_options" {
      for_each = (
        each.value.s3_config.cloudwatch_log_group != null &&
        each.value.s3_config.cloudwatch_log_stream != null
      ) ? [1] : []
      content {
        enabled         = true
        log_group_name  = each.value.s3_config.cloudwatch_log_group
        log_stream_name = each.value.s3_config.cloudwatch_log_stream
      }
    }

    # Lambda data transformation processor
    dynamic "processing_configuration" {
      for_each = each.value.s3_config.lambda_processor_arn != null ? [1] : []
      content {
        enabled = true
        processors {
          type = "Lambda"
          parameters {
            parameter_name  = "LambdaArn"
            parameter_value = "${each.value.s3_config.lambda_processor_arn}:$LATEST"
          }
          parameters {
            parameter_name  = "BufferSizeInMBs"
            parameter_value = "3"
          }
          parameters {
            parameter_name  = "BufferIntervalInSeconds"
            parameter_value = "60"
          }
        }
      }
    }

    # Dynamic partitioning — requires JQ processor and metadata extraction
    dynamic "dynamic_partitioning_configuration" {
      for_each = each.value.s3_config.dynamic_partitioning ? [1] : []
      content {
        enabled        = true
        retry_duration = 300
      }
    }

    # Parquet/ORC conversion via Glue schema registry
    dynamic "data_format_conversion_configuration" {
      for_each = each.value.s3_config.parquet_conversion ? [1] : []
      content {
        enabled = true

        input_format_configuration {
          deserializer {
            hive_json_ser_de {}
          }
        }

        output_format_configuration {
          serializer {
            parquet_ser_de {
              compression = "SNAPPY"
            }
          }
        }

        schema_configuration {
          role_arn      = var.create_iam_roles && var.create_firehose_role ? aws_iam_role.firehose[0].arn : null
          database_name = each.value.s3_config.glue_database
          table_name    = each.value.s3_config.glue_table
          region        = data.aws_region.current.name
        }
      }
    }
  }

  # Server-side encryption
  dynamic "server_side_encryption" {
    for_each = each.value.server_side_encryption != null ? [each.value.server_side_encryption] : []
    content {
      enabled  = server_side_encryption.value.enabled
      key_type = server_side_encryption.value.key_type
      key_arn  = server_side_encryption.value.key_arn
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name      = "${var.name_prefix}${each.key}"
    ManagedBy = "terraform"
  })
}

# ---------------------------------------------------------------------------
# Redshift destination
# ---------------------------------------------------------------------------

resource "aws_kinesis_firehose_delivery_stream" "redshift" {
  for_each = local.firehose_redshift

  name        = "${var.name_prefix}${each.key}"
  destination = "redshift"

  dynamic "kinesis_source_configuration" {
    for_each = each.value.source_stream_key != null ? [1] : []
    content {
      kinesis_stream_arn = aws_kinesis_stream.this[each.value.source_stream_key].arn
      role_arn           = var.create_iam_roles && var.create_firehose_role ? aws_iam_role.firehose[0].arn : null
    }
  }

  redshift_configuration {
    role_arn        = var.create_iam_roles && var.create_firehose_role ? aws_iam_role.firehose[0].arn : null
    cluster_jdbcurl = each.value.redshift_config.cluster_jdbcurl
    username        = each.value.redshift_config.username
    password        = each.value.redshift_config.password
    data_table_name = each.value.redshift_config.data_table_name
    copy_options    = each.value.redshift_config.copy_options
    s3_backup_mode  = each.value.redshift_config.s3_backup_mode

    s3_configuration {
      role_arn   = var.create_iam_roles && var.create_firehose_role ? aws_iam_role.firehose[0].arn : null
      bucket_arn = each.value.redshift_config.s3_bucket_arn
      prefix     = each.value.redshift_config.s3_prefix
    }
  }

  dynamic "server_side_encryption" {
    for_each = each.value.server_side_encryption != null ? [each.value.server_side_encryption] : []
    content {
      enabled  = server_side_encryption.value.enabled
      key_type = server_side_encryption.value.key_type
      key_arn  = server_side_encryption.value.key_arn
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name      = "${var.name_prefix}${each.key}"
    ManagedBy = "terraform"
  })
}

# ---------------------------------------------------------------------------
# OpenSearch (Elasticsearch) destination
# ---------------------------------------------------------------------------

resource "aws_kinesis_firehose_delivery_stream" "opensearch" {
  for_each = local.firehose_opensearch

  name        = "${var.name_prefix}${each.key}"
  destination = "opensearch"

  dynamic "kinesis_source_configuration" {
    for_each = each.value.source_stream_key != null ? [1] : []
    content {
      kinesis_stream_arn = aws_kinesis_stream.this[each.value.source_stream_key].arn
      role_arn           = var.create_iam_roles && var.create_firehose_role ? aws_iam_role.firehose[0].arn : null
    }
  }

  opensearch_configuration {
    role_arn           = var.create_iam_roles && var.create_firehose_role ? aws_iam_role.firehose[0].arn : null
    domain_arn         = each.value.opensearch_config.domain_arn
    index_name         = each.value.opensearch_config.index_name
    type_name          = each.value.opensearch_config.type_name
    buffering_size     = each.value.opensearch_config.buffering_size
    buffering_interval = each.value.opensearch_config.buffering_interval

    s3_configuration {
      role_arn   = var.create_iam_roles && var.create_firehose_role ? aws_iam_role.firehose[0].arn : null
      bucket_arn = each.value.opensearch_config.s3_bucket_arn
      prefix     = each.value.opensearch_config.s3_prefix
    }
  }

  dynamic "server_side_encryption" {
    for_each = each.value.server_side_encryption != null ? [each.value.server_side_encryption] : []
    content {
      enabled  = server_side_encryption.value.enabled
      key_type = server_side_encryption.value.key_type
      key_arn  = server_side_encryption.value.key_arn
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name      = "${var.name_prefix}${each.key}"
    ManagedBy = "terraform"
  })
}

# ---------------------------------------------------------------------------
# Splunk destination
# ---------------------------------------------------------------------------

resource "aws_kinesis_firehose_delivery_stream" "splunk" {
  for_each = local.firehose_splunk

  name        = "${var.name_prefix}${each.key}"
  destination = "splunk"

  dynamic "kinesis_source_configuration" {
    for_each = each.value.source_stream_key != null ? [1] : []
    content {
      kinesis_stream_arn = aws_kinesis_stream.this[each.value.source_stream_key].arn
      role_arn           = var.create_iam_roles && var.create_firehose_role ? aws_iam_role.firehose[0].arn : null
    }
  }

  splunk_configuration {
    hec_endpoint               = each.value.splunk_config.hec_endpoint
    hec_token                  = each.value.splunk_config.hec_token
    hec_endpoint_type          = each.value.splunk_config.hec_endpoint_type
    hec_acknowledgment_timeout = each.value.splunk_config.hec_acknowledgment_timeout

    s3_configuration {
      role_arn   = var.create_iam_roles && var.create_firehose_role ? aws_iam_role.firehose[0].arn : null
      bucket_arn = each.value.splunk_config.s3_bucket_arn
      prefix     = each.value.splunk_config.s3_prefix
    }
  }

  dynamic "server_side_encryption" {
    for_each = each.value.server_side_encryption != null ? [each.value.server_side_encryption] : []
    content {
      enabled  = server_side_encryption.value.enabled
      key_type = server_side_encryption.value.key_type
      key_arn  = server_side_encryption.value.key_arn
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name      = "${var.name_prefix}${each.key}"
    ManagedBy = "terraform"
  })
}

# ---------------------------------------------------------------------------
# HTTP endpoint destination
# ---------------------------------------------------------------------------

resource "aws_kinesis_firehose_delivery_stream" "http_endpoint" {
  for_each = local.firehose_http

  name        = "${var.name_prefix}${each.key}"
  destination = "http_endpoint"

  dynamic "kinesis_source_configuration" {
    for_each = each.value.source_stream_key != null ? [1] : []
    content {
      kinesis_stream_arn = aws_kinesis_stream.this[each.value.source_stream_key].arn
      role_arn           = var.create_iam_roles && var.create_firehose_role ? aws_iam_role.firehose[0].arn : null
    }
  }

  http_endpoint_configuration {
    url                = each.value.http_endpoint_config.url
    name               = each.value.http_endpoint_config.name
    access_key         = each.value.http_endpoint_config.access_key
    buffering_size     = each.value.http_endpoint_config.buffering_size
    buffering_interval = each.value.http_endpoint_config.buffering_interval
    role_arn           = var.create_iam_roles && var.create_firehose_role ? aws_iam_role.firehose[0].arn : null

    s3_configuration {
      role_arn   = var.create_iam_roles && var.create_firehose_role ? aws_iam_role.firehose[0].arn : null
      bucket_arn = each.value.http_endpoint_config.s3_bucket_arn
      prefix     = each.value.http_endpoint_config.s3_prefix
    }
  }

  dynamic "server_side_encryption" {
    for_each = each.value.server_side_encryption != null ? [each.value.server_side_encryption] : []
    content {
      enabled  = server_side_encryption.value.enabled
      key_type = server_side_encryption.value.key_type
      key_arn  = server_side_encryption.value.key_arn
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name      = "${var.name_prefix}${each.key}"
    ManagedBy = "terraform"
  })
}
