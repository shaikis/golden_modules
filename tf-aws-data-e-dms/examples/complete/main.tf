# Complete example demonstrating three migration scenarios:
#
# 1. Oracle (on-prem) → S3 (data lake landing zone) — full-load + CDC
# 2. RDS PostgreSQL → Redshift (analytics)           — full-load + CDC
# 3. MySQL RDS → Aurora MySQL (homogeneous)           — full-load + CDC
#
# All tasks use CDC, CloudWatch alarms, and DMS event subscriptions.

module "dms" {
  source = "../../"

  # Feature gates
  create_alarms              = true
  create_event_subscriptions = true
  create_iam_roles           = true
  create_certificates        = false # set true and populate var.certificates for SSL

  alarm_sns_topic_arn = var.alarm_sns_topic_arn
  kms_key_arn         = var.kms_key_arn

  alarm_cdc_latency_source_threshold = 60
  alarm_cdc_latency_target_threshold = 120
  alarm_evaluation_periods           = 3
  alarm_period_seconds               = 300

  # -------------------------------------------------------------------------
  # Replication subnet group
  # -------------------------------------------------------------------------
  subnet_groups = {
    dms-private = {
      description = "DMS replication subnet group — private subnets"
      subnet_ids  = ["subnet-private1", "subnet-private2", "subnet-private3"]
    }
  }

  # -------------------------------------------------------------------------
  # Replication instances
  # -------------------------------------------------------------------------
  replication_instances = {
    # Large instance for Oracle → S3 (high LOB column volume)
    oracle-migration = {
      replication_instance_class   = "dms.r5.large"
      allocated_storage            = 200
      multi_az                     = true
      engine_version               = "3.5.2"
      publicly_accessible          = false
      vpc_security_group_ids       = ["sg-dms-oracle"]
      replication_subnet_group_id  = "dms-private"
      preferred_maintenance_window = "sun:04:00-sun:04:30"
      tags = {
        Migration = "oracle-to-s3"
      }
    }

    # Medium instance for PG → Redshift
    pg-migration = {
      replication_instance_class  = "dms.t3.large"
      allocated_storage           = 100
      multi_az                    = true
      engine_version              = "3.5.2"
      publicly_accessible         = false
      vpc_security_group_ids      = ["sg-dms-pg"]
      replication_subnet_group_id = "dms-private"
      tags = {
        Migration = "pg-to-redshift"
      }
    }

    # Small instance for MySQL → Aurora (homogeneous, lower overhead)
    mysql-migration = {
      replication_instance_class  = "dms.t3.medium"
      allocated_storage           = 50
      multi_az                    = false
      engine_version              = "3.5.2"
      publicly_accessible         = false
      vpc_security_group_ids      = ["sg-dms-mysql"]
      replication_subnet_group_id = "dms-private"
      tags = {
        Migration = "mysql-to-aurora"
      }
    }
  }

  # -------------------------------------------------------------------------
  # Endpoints
  # -------------------------------------------------------------------------
  endpoints = {
    # Oracle source — use Secrets Manager for credentials
    oracle-source = {
      endpoint_type               = "source"
      engine_name                 = "oracle"
      server_name                 = var.oracle_server_name
      port                        = 1521
      database_name               = "ORCL"
      ssl_mode                    = "none"
      secrets_manager_arn         = "arn:aws:secretsmanager:us-east-1:123456789012:secret:dms/oracle-source"
      extra_connection_attributes = "addSupplementalLogging=Y;useLogminerReader=N;useBfile=Y"
    }

    # S3 target — data lake landing zone in Parquet format
    s3-landing = {
      endpoint_type = "target"
      engine_name   = "s3"

      s3_settings = {
        bucket_name                      = var.s3_landing_bucket
        bucket_folder                    = "oracle/raw"
        compression_type                 = "GZIP"
        data_format                      = "parquet"
        parquet_version                  = "parquet-2-0"
        enable_statistics                = true
        include_op_for_full_load         = true
        timestamp_column_name            = "dms_timestamp"
        service_access_role_arn          = var.dms_s3_service_role_arn
        cdc_inserts_and_updates          = true
        encoding_type                    = "plain-dictionary"
        row_group_length                 = 10000
        data_page_size                   = 1048576
        parquet_timestamp_in_millisecond = true
      }
    }

    # PostgreSQL source
    pg-source = {
      endpoint_type               = "source"
      engine_name                 = "postgres"
      server_name                 = var.pg_server_name
      port                        = 5432
      database_name               = "appdb"
      ssl_mode                    = "require"
      secrets_manager_arn         = "arn:aws:secretsmanager:us-east-1:123456789012:secret:dms/pg-source"
      extra_connection_attributes = "captureDdls=Y;pluginName=pglogical"
    }

    # Redshift target
    redshift-target = {
      endpoint_type       = "target"
      engine_name         = "redshift"
      server_name         = var.redshift_server_name
      port                = 5439
      database_name       = "analytics"
      ssl_mode            = "require"
      secrets_manager_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:dms/redshift-target"

      redshift_settings = {
        bucket_name                       = var.s3_landing_bucket
        bucket_folder                     = "redshift-staging"
        service_access_role_arn           = var.dms_s3_service_role_arn
        encryption_mode                   = "SSE_KMS"
        server_side_encryption_kms_key_id = var.kms_key_arn
        accept_any_date                   = true
        date_format                       = "AUTO"
        time_format                       = "AUTO"
        empty_as_null                     = true
        trim_blanks                       = true
        truncate_columns                  = false
      }
    }

    # MySQL RDS source
    mysql-source = {
      endpoint_type               = "source"
      engine_name                 = "mysql"
      server_name                 = var.mysql_server_name
      port                        = 3306
      database_name               = "appdb"
      ssl_mode                    = "require"
      secrets_manager_arn         = "arn:aws:secretsmanager:us-east-1:123456789012:secret:dms/mysql-source"
      extra_connection_attributes = "eventsPollInterval=5;parallelLoadThreads=4"
    }

    # Aurora MySQL target
    aurora-target = {
      endpoint_type       = "target"
      engine_name         = "aurora"
      server_name         = var.aurora_server_name
      port                = 3306
      database_name       = "appdb"
      ssl_mode            = "require"
      secrets_manager_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:dms/aurora-target"
    }
  }

  # -------------------------------------------------------------------------
  # Replication tasks
  # -------------------------------------------------------------------------
  replication_tasks = {
    oracle-to-s3 = {
      replication_instance_key = "oracle-migration"
      source_endpoint_key      = "oracle-source"
      target_endpoint_key      = "s3-landing"
      migration_type           = "full-load-and-cdc"
      start_replication_task   = false

      table_mappings = jsonencode({
        rules = [
          {
            rule-type = "selection"
            rule-id   = "1"
            rule-name = "include-app-schema"
            object-locator = {
              schema-name = "APPSCHEMA"
              table-name  = "%"
            }
            rule-action = "include"
          },
          {
            rule-type = "selection"
            rule-id   = "2"
            rule-name = "exclude-audit-table"
            object-locator = {
              schema-name = "APPSCHEMA"
              table-name  = "AUDIT_LOG"
            }
            rule-action = "exclude"
          }
        ]
      })

      tags = {
        Migration = "oracle-to-s3"
        Phase     = "full-load-and-cdc"
      }
    }

    pg-to-redshift = {
      replication_instance_key = "pg-migration"
      source_endpoint_key      = "pg-source"
      target_endpoint_key      = "redshift-target"
      migration_type           = "full-load-and-cdc"
      start_replication_task   = false

      table_mappings = jsonencode({
        rules = [
          {
            rule-type = "selection"
            rule-id   = "1"
            rule-name = "include-public"
            object-locator = {
              schema-name = "public"
              table-name  = "%"
            }
            rule-action = "include"
          },
          {
            rule-type   = "transformation"
            rule-id     = "2"
            rule-name   = "lowercase-schema"
            rule-action = "convert-lowercase"
            rule-target = "schema"
            object-locator = {
              schema-name = "%"
            }
          }
        ]
      })

      tags = {
        Migration = "pg-to-redshift"
        Phase     = "full-load-and-cdc"
      }
    }

    mysql-to-aurora = {
      replication_instance_key = "mysql-migration"
      source_endpoint_key      = "mysql-source"
      target_endpoint_key      = "aurora-target"
      migration_type           = "full-load-and-cdc"
      start_replication_task   = false

      table_mappings = jsonencode({
        rules = [
          {
            rule-type = "selection"
            rule-id   = "1"
            rule-name = "include-all"
            object-locator = {
              schema-name = "appdb"
              table-name  = "%"
            }
            rule-action = "include"
          }
        ]
      })

      tags = {
        Migration = "mysql-to-aurora"
        Phase     = "full-load-and-cdc"
      }
    }
  }

  # -------------------------------------------------------------------------
  # DMS Event subscriptions
  # -------------------------------------------------------------------------
  event_subscriptions = {
    task-failure = {
      sns_topic_arn = var.alarm_sns_topic_arn != null ? var.alarm_sns_topic_arn : "arn:aws:sns:us-east-1:123456789012:dms-alerts"
      source_type   = "replication-task"
      source_ids    = ["oracle-to-s3", "pg-to-redshift", "mysql-to-aurora"]
      event_categories = [
        "failure",
        "state change",
        "deletion",
      ]
    }

    instance-failure = {
      sns_topic_arn = var.alarm_sns_topic_arn != null ? var.alarm_sns_topic_arn : "arn:aws:sns:us-east-1:123456789012:dms-alerts"
      source_type   = "replication-instance"
      source_ids    = ["oracle-migration", "pg-migration", "mysql-migration"]
      event_categories = [
        "failure",
        "failover",
        "maintenance",
        "deletion",
        "creation",
      ]
    }
  }

  tags = {
    Project     = "data-migration"
    ManagedBy   = "terraform"
    Environment = "production"
  }
}
