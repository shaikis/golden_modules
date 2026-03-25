# ---------------------------------------------------------------------------
# Complete example — production-grade daily ETL pipeline
#
# Architecture:
#   S3 Raw Zone ──► Crawl ──► ingest_raw (glueetl) ──► Processed Zone
#                                                        │
#                                              ┌─────────┴──────────┐
#                                         transform_orders    aggregate_daily
#                                              │                    │
#                                         Analytics Zone     Analytics Zone
#
# Additional jobs:
#   python_utility  — metadata maintenance (pythonshell)
#   streaming_cdc   — Kafka → S3 CDC (gluestreaming)
# ---------------------------------------------------------------------------

locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "terraform"
    },
    var.tags
  )

  name_prefix = "${var.project}-${var.environment}-"
}

module "glue" {
  source = "../../"

  # ── Feature gates — enable what you need ──────────────────────────────────
  create_catalog_databases       = true
  create_crawlers                = true
  create_triggers                = true
  create_workflows               = true
  create_connections             = true
  create_schema_registries       = true
  create_security_configurations = true
  create_catalog_encryption      = true
  create_iam_role                = true

  name_prefix = local.name_prefix
  tags        = local.common_tags

  # -------------------------------------------------------------------------
  # Data lake bucket access + KMS
  # -------------------------------------------------------------------------

  data_lake_bucket_arns = [
    "arn:aws:s3:::${var.data_lake_bucket_name}",
    "arn:aws:s3:::${var.assets_bucket_name}",
  ]

  kms_key_arns = [var.glue_kms_key_arn]

  enable_secrets_manager_access = true

  # -------------------------------------------------------------------------
  # 3 Catalog Databases
  # -------------------------------------------------------------------------

  catalog_databases = {
    raw_zone = {
      description  = "Raw ingestion zone — unmodified source data."
      location_uri = "s3://${var.data_lake_bucket_name}/raw/"
      parameters = {
        data_zone = "raw"
        layer     = "bronze"
      }
    }

    processed_zone = {
      description  = "Processed zone — cleansed and partitioned Parquet."
      location_uri = "s3://${var.data_lake_bucket_name}/processed/"
      parameters = {
        data_zone = "processed"
        layer     = "silver"
      }
    }

    analytics_zone = {
      description  = "Analytics zone — aggregated, query-optimised tables."
      location_uri = "s3://${var.data_lake_bucket_name}/analytics/"
      parameters = {
        data_zone = "analytics"
        layer     = "gold"
      }
    }
  }

  # -------------------------------------------------------------------------
  # Security Configuration
  # -------------------------------------------------------------------------

  security_configurations = {
    default_kms = {
      s3_encryption_mode         = "SSE-KMS"
      s3_kms_key_arn             = var.glue_kms_key_arn
      cloudwatch_encryption_mode = "SSE-KMS"
      cloudwatch_kms_key_arn     = var.glue_kms_key_arn
      bookmark_encryption_mode   = "CSE-KMS"
      bookmark_kms_key_arn       = var.glue_kms_key_arn
    }
  }

  # -------------------------------------------------------------------------
  # Connections
  # -------------------------------------------------------------------------

  connections = {
    rds_postgres = {
      connection_type = "JDBC"
      description     = "JDBC connection to source RDS PostgreSQL database."
      connection_properties = {
        JDBC_CONNECTION_URL = var.rds_jdbc_url
        USERNAME            = var.rds_username
        PASSWORD            = var.rds_password
        JDBC_ENFORCE_SSL    = "true"
      }
      subnet_id          = var.rds_subnet_id
      security_group_ids = [var.rds_security_group_id]
      availability_zone  = var.rds_availability_zone
    }

    kafka_msk = {
      connection_type = "KAFKA"
      description     = "Kafka connection to Amazon MSK cluster."
      connection_properties = {
        KAFKA_BOOTSTRAP_SERVERS = var.msk_bootstrap_servers
        KAFKA_SSL_ENABLED       = "true"
      }
      subnet_id          = var.msk_subnet_id
      security_group_ids = [var.msk_security_group_id]
    }
  }

  # -------------------------------------------------------------------------
  # 3 Crawlers
  # -------------------------------------------------------------------------

  crawlers = {
    s3_raw_crawler = {
      database_name          = "${local.name_prefix}raw_zone"
      description            = "Crawls the S3 raw zone and registers tables in the Glue catalog."
      security_configuration = "${local.name_prefix}default_kms"
      table_prefix           = "raw_"

      s3_targets = [
        {
          path       = "s3://${var.data_lake_bucket_name}/raw/orders/"
          exclusions = ["**/_temporary/**", "**/.spark-staging/**"]
        },
        {
          path       = "s3://${var.data_lake_bucket_name}/raw/customers/"
          exclusions = ["**/_temporary/**"]
        },
      ]

      schema_change_policy = {
        delete_behavior = "LOG"
        update_behavior = "UPDATE_IN_DATABASE"
      }

      recrawl_policy = "CRAWL_NEW_FOLDERS_ONLY"
      lineage        = true

      configuration = jsonencode({
        Version = 1.0
        CrawlerOutput = {
          Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
          Tables     = { AddOrUpdateBehavior = "MergeNewColumns" }
        }
        Grouping = {
          TableGroupingPolicy     = "CombineCompatibleSchemas"
          TableLevelConfiguration = 3
        }
      })

      tags = { crawler_type = "s3" }
    }

    rds_jdbc_crawler = {
      database_name          = "${local.name_prefix}raw_zone"
      description            = "Crawls the RDS source schema and registers tables in the Glue catalog."
      security_configuration = "${local.name_prefix}default_kms"
      table_prefix           = "rds_"

      jdbc_targets = [
        {
          connection_name = "${local.name_prefix}rds_postgres"
          path            = "public/%"
          exclusions      = ["public/pg_%", "public/information_%"]
        },
      ]

      schema_change_policy = {
        delete_behavior = "LOG"
        update_behavior = "UPDATE_IN_DATABASE"
      }

      recrawl_policy = "CRAWL_NEW_FOLDERS_ONLY"

      tags = { crawler_type = "jdbc" }
    }

    delta_lake_crawler = {
      database_name          = "${local.name_prefix}processed_zone"
      description            = "Crawls Delta Lake tables in the processed zone."
      security_configuration = "${local.name_prefix}default_kms"
      table_prefix           = "delta_"

      delta_target = [
        {
          delta_tables   = ["s3://${var.data_lake_bucket_name}/processed/orders_delta/"]
          write_manifest = true
        },
      ]

      schema_change_policy = {
        delete_behavior = "LOG"
        update_behavior = "UPDATE_IN_DATABASE"
      }

      recrawl_policy = "CRAWL_NEW_FOLDERS_ONLY"

      tags = { crawler_type = "delta" }
    }
  }

  # -------------------------------------------------------------------------
  # 5 Glue Jobs
  # -------------------------------------------------------------------------

  jobs = {
    # Job 1 — Ingest raw S3 data → processed zone as Parquet
    ingest_raw = {
      description            = "Reads raw data from S3, applies schema validation, writes Parquet to processed zone."
      script_location        = "s3://${var.assets_bucket_name}/scripts/ingest_raw.py"
      glue_version           = "4.0"
      job_type               = "glueetl"
      worker_type            = "G.1X"
      number_of_workers      = 4
      max_retries            = 2
      timeout                = 120
      execution_class        = "STANDARD"
      max_concurrent_runs    = 1
      notify_delay_after     = 30
      security_configuration = "${local.name_prefix}default_kms"
      bookmark_option        = "job-bookmark-enable"
      default_arguments = {
        "--source_database"  = "${local.name_prefix}raw_zone"
        "--target_database"  = "${local.name_prefix}processed_zone"
        "--source_path"      = "s3://${var.data_lake_bucket_name}/raw/"
        "--target_path"      = "s3://${var.data_lake_bucket_name}/processed/"
        "--output_format"    = "parquet"
        "--compression_type" = "snappy"
      }
      tags = { pipeline_stage = "ingest" }
    }

    # Job 2 — Transform orders + customers join → analytics zone
    transform_orders = {
      description            = "Joins orders with customers dimension, enriches and writes to analytics zone."
      script_location        = "s3://${var.assets_bucket_name}/scripts/transform_orders.py"
      glue_version           = "4.0"
      job_type               = "glueetl"
      worker_type            = "G.2X"
      number_of_workers      = 8
      max_retries            = 1
      timeout                = 180
      execution_class        = "STANDARD"
      max_concurrent_runs    = 1
      security_configuration = "${local.name_prefix}default_kms"
      bookmark_option        = "job-bookmark-enable"
      default_arguments = {
        "--orders_table"    = "processed_orders"
        "--customers_table" = "processed_customers"
        "--target_path"     = "s3://${var.data_lake_bucket_name}/analytics/orders_enriched/"
        "--partition_by"    = "order_date"
      }
      tags = { pipeline_stage = "transform" }
    }

    # Job 3 — Daily aggregation to analytics zone (FLEX for cost savings)
    aggregate_daily = {
      description            = "Aggregates order metrics daily and writes summary tables to analytics zone."
      script_location        = "s3://${var.assets_bucket_name}/scripts/aggregate_daily.py"
      glue_version           = "4.0"
      job_type               = "glueetl"
      worker_type            = "G.1X"
      number_of_workers      = 4
      max_retries            = 1
      timeout                = 240
      execution_class        = "FLEX"
      max_concurrent_runs    = 1
      security_configuration = "${local.name_prefix}default_kms"
      bookmark_option        = "job-bookmark-enable"
      default_arguments = {
        "--source_database" = "${local.name_prefix}processed_zone"
        "--target_path"     = "s3://${var.data_lake_bucket_name}/analytics/daily_aggregates/"
        "--aggregation_key" = "order_date"
      }
      tags = { pipeline_stage = "aggregate", cost_optimised = "true" }
    }

    # Job 4 — Python Shell utility for lightweight metadata maintenance
    python_utility = {
      description            = "Python shell job for metadata maintenance — partition repair, stats updates."
      script_location        = "s3://${var.assets_bucket_name}/scripts/python_utility.py"
      glue_version           = "1.0"
      job_type               = "pythonshell"
      python_version         = "3.9"
      worker_type            = null
      number_of_workers      = null
      max_retries            = 0
      timeout                = 60
      execution_class        = "STANDARD"
      max_concurrent_runs    = 3
      security_configuration = "${local.name_prefix}default_kms"
      bookmark_option        = "job-bookmark-disable"
      default_arguments = {
        "--action"    = "repair_partitions"
        "--databases" = "${local.name_prefix}processed_zone,${local.name_prefix}analytics_zone"
      }
      tags = { pipeline_stage = "utility" }
    }

    # Job 5 — Streaming CDC from Kafka → S3
    streaming_cdc = {
      description            = "Reads CDC events from MSK Kafka, deduplicates and writes micro-batches to S3 raw zone."
      script_location        = "s3://${var.assets_bucket_name}/scripts/streaming_cdc.py"
      glue_version           = "4.0"
      job_type               = "gluestreaming"
      worker_type            = "G.025X"
      number_of_workers      = 2
      max_retries            = 0
      timeout                = 0
      execution_class        = "STANDARD"
      max_concurrent_runs    = 1
      connections            = ["${local.name_prefix}kafka_msk"]
      security_configuration = "${local.name_prefix}default_kms"
      bookmark_option        = "job-bookmark-disable"
      default_arguments = {
        "--kafka_topic"         = "db.public.orders"
        "--checkpoint_location" = "s3://${var.data_lake_bucket_name}/checkpoints/streaming_cdc/"
        "--output_path"         = "s3://${var.data_lake_bucket_name}/raw/cdc/"
        "--window_size"         = "100 seconds"
        "--starting_offsets"    = "latest"
      }
      tags = { pipeline_stage = "streaming" }
    }
  }

  # -------------------------------------------------------------------------
  # 1 Workflow
  # -------------------------------------------------------------------------

  workflows = {
    daily_etl_pipeline = {
      description = "Orchestrates the daily batch ETL pipeline from raw ingestion to analytics aggregation."
      default_run_properties = {
        pipeline_version = "1.0"
        environment      = var.environment
      }
      max_concurrent_runs = 1
      tags                = { pipeline = "daily_etl" }
    }
  }

  # -------------------------------------------------------------------------
  # 3 Triggers
  # -------------------------------------------------------------------------

  triggers = {
    # Trigger 1 — Scheduled daily at 01:00 UTC, starts the S3 raw crawler
    start_crawl = {
      type              = "SCHEDULED"
      description       = "Starts the S3 raw zone crawler daily at 01:00 UTC."
      workflow_name     = "${local.name_prefix}daily_etl_pipeline"
      schedule          = "cron(0 1 * * ? *)"
      enabled           = true
      start_on_creation = true

      actions = [
        {
          crawler_name = "${local.name_prefix}s3_raw_crawler"
          timeout      = 60
        },
      ]

      tags = { trigger_type = "scheduled" }
    }

    # Trigger 2 — Conditional: after s3_raw_crawler SUCCEEDED, start ingest_raw job
    after_crawl = {
      type          = "CONDITIONAL"
      description   = "Starts ingest_raw ETL job after the S3 raw crawler succeeds."
      workflow_name = "${local.name_prefix}daily_etl_pipeline"
      enabled       = true

      actions = [
        {
          job_name = "${local.name_prefix}ingest_raw"
          arguments = {
            "--run_date" = "auto"
          }
        },
      ]

      predicate = {
        logical = "AND"
        conditions = [
          {
            crawler_name     = "${local.name_prefix}s3_raw_crawler"
            crawl_state      = "SUCCEEDED"
            logical_operator = "EQUALS"
          },
        ]
      }

      tags = { trigger_type = "conditional" }
    }

    # Trigger 3 — Conditional: after ingest_raw SUCCEEDED, start transform_orders AND aggregate_daily in parallel
    after_ingest = {
      type          = "CONDITIONAL"
      description   = "Starts transform_orders and aggregate_daily in parallel after ingest_raw succeeds."
      workflow_name = "${local.name_prefix}daily_etl_pipeline"
      enabled       = true

      actions = [
        {
          job_name = "${local.name_prefix}transform_orders"
        },
        {
          job_name = "${local.name_prefix}aggregate_daily"
        },
      ]

      predicate = {
        logical = "AND"
        conditions = [
          {
            job_name         = "${local.name_prefix}ingest_raw"
            state            = "SUCCEEDED"
            logical_operator = "EQUALS"
          },
        ]
      }

      tags = { trigger_type = "conditional" }
    }
  }

  # -------------------------------------------------------------------------
  # 2 Schema Registries
  # -------------------------------------------------------------------------

  schema_registries = {
    events_registry = {
      description = "Avro schemas for domain events produced by the orders service."
      schemas = {
        order_created = {
          schema_name   = "order_created"
          description   = "Schema for OrderCreated domain event."
          data_format   = "AVRO"
          compatibility = "BACKWARD"
          schema_definition = jsonencode({
            type      = "record"
            name      = "OrderCreated"
            namespace = "com.example.orders"
            fields = [
              { name = "order_id", type = "string" },
              { name = "customer_id", type = "string" },
              { name = "order_date", type = "string" },
              { name = "total_amount", type = "double" },
              { name = "currency", type = "string", default = "USD" },
              { name = "status", type = "string" },
            ]
          })
          tags = { domain = "orders" }
        }

        order_updated = {
          schema_name   = "order_updated"
          description   = "Schema for OrderUpdated domain event."
          data_format   = "AVRO"
          compatibility = "BACKWARD"
          schema_definition = jsonencode({
            type      = "record"
            name      = "OrderUpdated"
            namespace = "com.example.orders"
            fields = [
              { name = "order_id", type = "string" },
              { name = "updated_at", type = "string" },
              { name = "status", type = "string" },
              { name = "previous_status", type = ["null", "string"], default = null },
            ]
          })
          tags = { domain = "orders" }
        }
      }
      tags = { domain = "events" }
    }

    cdc_registry = {
      description = "JSON schemas for CDC records captured from RDS."
      schemas = {
        orders_cdc = {
          schema_name   = "orders_cdc"
          description   = "JSON schema for orders CDC records from Debezium."
          data_format   = "JSON"
          compatibility = "FORWARD"
          schema_definition = jsonencode({
            "$schema" = "http://json-schema.org/draft-07/schema#"
            title     = "OrdersCDC"
            type      = "object"
            required  = ["op", "ts_ms", "source"]
            properties = {
              op     = { type = "string", enum = ["c", "u", "d", "r"] }
              ts_ms  = { type = "integer" }
              before = { type = ["object", "null"] }
              after  = { type = ["object", "null"] }
              source = { type = "object" }
            }
          })
          tags = { domain = "cdc" }
        }
      }
      tags = { domain = "cdc" }
    }
  }

  # -------------------------------------------------------------------------
  # Catalog encryption
  # -------------------------------------------------------------------------

  catalog_encryption_kms_key_id                     = var.glue_kms_key_arn
  catalog_connection_password_encryption_kms_key_id = var.glue_kms_key_arn
}
