# ---------------------------------------------------------------------------
# Complete example — showcases all major module features
#
# Resources created:
#   Kinesis Data Streams:
#     • events      — ON_DEMAND (auto-scaling shards)
#     • orders      — 4 shards, 168h retention (7-day replay window)
#     • clickstream — 8 shards, high-throughput ingestion
#
#   Firehose Delivery Streams:
#     • events_to_s3        — events stream → S3 (GZIP, dynamic partitioning)
#     • orders_to_redshift  — orders stream → Redshift + S3 backup
#
#   Analytics:
#     • clickstream_processor — Flink 1.18 app reading from clickstream stream
#
#   Enhanced Fan-Out:
#     • orders_analytics_consumer — dedicated 2 MB/s read from orders
#
#   IAM, CloudWatch Alarms for all resources above
# ---------------------------------------------------------------------------

module "kinesis" {
  source = "../../"

  name_prefix = var.name_prefix

  tags = {
    Environment = var.environment
    Project     = var.project
  }

  # ── Feature gates — enable what you need ──────────────────────────────────
  create_firehose_streams       = true
  create_analytics_applications = true
  create_stream_consumers       = true
  create_alarms                 = true
  create_iam_roles              = true

  # -------------------------------------------------------------------------
  # Kinesis Data Streams
  # -------------------------------------------------------------------------

  kinesis_streams = {
    # ON_DEMAND stream — AWS auto-scales shards based on traffic
    events = {
      on_demand        = true
      retention_period = 24
      encryption_type  = "KMS"
      kms_key_id       = var.kms_key_id
      tags = {
        DataClassification = "internal"
        Team               = "platform"
      }
    }

    # PROVISIONED stream — predictable capacity, 7-day retention for replay
    orders = {
      shard_count      = 4
      on_demand        = false
      retention_period = 168 # 7 days
      shard_level_metrics = [
        "IncomingBytes",
        "IncomingRecords",
        "OutgoingBytes",
        "OutgoingRecords",
        "WriteProvisionedThroughputExceeded",
        "ReadProvisionedThroughputExceeded",
        "IteratorAgeMilliseconds",
      ]
      encryption_type           = "KMS"
      kms_key_id                = var.kms_key_id
      enforce_consumer_deletion = false
      tags = {
        DataClassification = "confidential"
        Team               = "commerce"
      }
    }

    # High-throughput stream for clickstream analytics
    clickstream = {
      shard_count      = 8
      on_demand        = false
      retention_period = 48
      shard_level_metrics = [
        "IncomingBytes",
        "IncomingRecords",
        "OutgoingBytes",
        "OutgoingRecords",
        "WriteProvisionedThroughputExceeded",
        "ReadProvisionedThroughputExceeded",
        "IteratorAgeMilliseconds",
      ]
      encryption_type = "KMS"
      kms_key_id      = var.kms_key_id
      tags = {
        DataClassification = "internal"
        Team               = "analytics"
      }
    }
  }

  # -------------------------------------------------------------------------
  # Enhanced Fan-Out Consumers
  # -------------------------------------------------------------------------

  stream_consumers = {
    orders_analytics_consumer = {
      stream_key    = "orders"
      consumer_name = "${var.name_prefix}orders-analytics-efo"
    }
  }

  # -------------------------------------------------------------------------
  # Firehose Delivery Streams
  # -------------------------------------------------------------------------

  firehose_streams = {
    # events → S3 with GZIP compression, dynamic partitioning, Lambda transform
    events_to_s3 = {
      source_stream_key = "events"
      destination       = "s3"

      s3_config = {
        bucket_arn           = var.data_lake_bucket_arn
        prefix               = "events/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
        error_output_prefix  = "errors/events/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
        buffering_size       = 128
        buffering_interval   = 300
        compression_format   = "GZIP"
        kms_key_arn          = var.s3_kms_key_arn
        lambda_processor_arn = var.lambda_processor_arn
        dynamic_partitioning = true
      }

      server_side_encryption = {
        enabled  = true
        key_type = "AWS_OWNED_CMK"
        key_arn  = null
      }

      tags = {
        Pipeline = "events-ingestion"
      }
    }

    # orders → Redshift for transactional analytics
    orders_to_redshift = {
      source_stream_key = "orders"
      destination       = "redshift"

      redshift_config = {
        cluster_jdbcurl = var.redshift_jdbc_url
        username        = var.redshift_username
        password        = var.redshift_password
        data_table_name = "raw_orders"
        copy_options    = "EMPTYASNULL BLANKSASNULL TRIMBLANKS"
        s3_backup_mode  = "FailedDocumentsOnly"
        s3_bucket_arn   = var.redshift_backup_bucket_arn
        s3_prefix       = "redshift-backup/orders/"
      }

      tags = {
        Pipeline = "orders-warehouse"
      }
    }
  }

  # -------------------------------------------------------------------------
  # Kinesis Data Analytics v2 — Flink 1.18
  # -------------------------------------------------------------------------

  analytics_applications = {
    clickstream_processor = {
      runtime_environment           = "FLINK-1_18"
      code_s3_bucket                = var.flink_code_s3_bucket
      code_s3_key                   = var.flink_code_s3_key
      parallelism                   = 4
      parallelism_per_kpu           = 1
      auto_scaling_enabled          = true
      checkpoint_enabled            = true
      checkpoint_interval           = 60000 # 60 seconds
      min_pause_between_checkpoints = 5000
      log_level                     = "INFO"
      metrics_level                 = "OPERATOR"
      start_application             = false # Set to true after JAR is uploaded

      environment_properties = {
        "source.stream.name"        = "${var.name_prefix}clickstream"
        "source.stream.region"      = "us-east-1"
        "sink.output.bucket"        = "your-analytics-output-bucket"
        "checkpoint.storage.bucket" = var.flink_code_s3_bucket
        "processing.window.seconds" = "60"
      }

      cloudwatch_log_stream_arn = var.analytics_log_stream_arn

      tags = {
        Application = "clickstream-real-time-analytics"
        Team        = "analytics"
      }
    }
  }

  # -------------------------------------------------------------------------
  # IAM
  # -------------------------------------------------------------------------

  create_producer_role         = true
  create_consumer_role         = true
  create_firehose_role         = true
  create_lambda_transform_role = true

  # -------------------------------------------------------------------------
  # CloudWatch Alarms
  # -------------------------------------------------------------------------

  alarm_sns_topic_arn                  = var.alarm_sns_topic_arn
  iterator_age_threshold_ms            = 60000 # 1 minute
  put_records_failed_threshold         = 0
  firehose_freshness_threshold_seconds = 900 # 15 minutes
  firehose_success_threshold           = 0.99
  alarm_evaluation_periods             = 2
  alarm_period_seconds                 = 300
}
