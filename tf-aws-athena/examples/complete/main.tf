module "athena" {
  source = "../../"

  name_prefix = var.name_prefix
  tags        = var.tags

  # -------------------------------------------------------------------------
  # Workgroups
  # -------------------------------------------------------------------------
  workgroups = {
    # Default workgroup — Athena engine v3, SSE-KMS, 10 GB scan limit
    primary = {
      description                        = "Primary shared workgroup with strict scan limit and KMS encryption."
      state                              = "ENABLED"
      enforce_workgroup_configuration    = true
      publish_cloudwatch_metrics_enabled = true
      bytes_scanned_cutoff_per_query     = 10737418240 # 10 GB
      engine_version                     = "Athena engine version 3"
      force_destroy                      = true

      result_configuration = {
        output_location       = "s3://${var.results_bucket_name}/primary/"
        encryption_type       = "SSE_KMS"
        kms_key_arn           = var.results_kms_key_arn
        expected_bucket_owner = var.account_id
        s3_acl_option         = null
      }

      tags = { Workgroup = "primary" }
    }

    # Data science — ML/exploration, no scan limit, separate results prefix
    data_science = {
      description                        = "Data science workgroup for ML and exploratory analysis — no scan limit."
      state                              = "ENABLED"
      enforce_workgroup_configuration    = false
      publish_cloudwatch_metrics_enabled = true
      bytes_scanned_cutoff_per_query     = null
      engine_version                     = "Athena engine version 3"
      force_destroy                      = true

      result_configuration = {
        output_location       = "s3://${var.results_bucket_name}/data-science/"
        encryption_type       = "SSE_KMS"
        kms_key_arn           = var.results_kms_key_arn
        expected_bucket_owner = var.account_id
        s3_acl_option         = null
      }

      tags = { Workgroup = "data-science", Team = "ml" }
    }

    # ETL pipelines — Glue/pipeline queries, BUCKET_OWNER_FULL_CONTROL ACL
    etl_pipelines = {
      description                        = "ETL pipeline workgroup — cross-account S3 writes with full-control ACL."
      state                              = "ENABLED"
      enforce_workgroup_configuration    = true
      publish_cloudwatch_metrics_enabled = true
      bytes_scanned_cutoff_per_query     = 107374182400 # 100 GB
      engine_version                     = "Athena engine version 3"
      force_destroy                      = false

      result_configuration = {
        output_location       = "s3://${var.results_bucket_name}/etl-pipelines/"
        encryption_type       = "SSE_KMS"
        kms_key_arn           = var.results_kms_key_arn
        expected_bucket_owner = var.account_id
        s3_acl_option         = "BUCKET_OWNER_FULL_CONTROL"
      }

      tags = { Workgroup = "etl-pipelines", Team = "data-engineering" }
    }

    # Reporting — enforced config, 5 GB scan limit, SSE-S3 (BI tooling)
    reporting = {
      description                        = "Reporting workgroup for BI dashboards — enforced 5 GB scan limit."
      state                              = "ENABLED"
      enforce_workgroup_configuration    = true
      publish_cloudwatch_metrics_enabled = true
      bytes_scanned_cutoff_per_query     = 5368709120 # 5 GB
      engine_version                     = "Athena engine version 3"
      force_destroy                      = false

      result_configuration = {
        output_location       = "s3://${var.results_bucket_name}/reporting/"
        encryption_type       = "SSE_S3"
        kms_key_arn           = null
        expected_bucket_owner = var.account_id
        s3_acl_option         = null
      }

      tags = { Workgroup = "reporting", Team = "analytics" }
    }
  }

  # -------------------------------------------------------------------------
  # Databases
  # -------------------------------------------------------------------------
  databases = {
    raw_zone = {
      bucket                = var.data_lake_bucket_name
      comment               = "Raw landing zone — unprocessed source data."
      encryption_type       = "SSE_KMS"
      kms_key_arn           = var.results_kms_key_arn
      expected_bucket_owner = var.account_id
      force_destroy         = false
      properties            = { classification = "raw" }
    }

    processed_zone = {
      bucket                = var.data_lake_bucket_name
      comment               = "Processed zone — cleaned, deduplicated Parquet/Iceberg data."
      encryption_type       = "SSE_KMS"
      kms_key_arn           = var.results_kms_key_arn
      expected_bucket_owner = var.account_id
      force_destroy         = false
      properties            = { classification = "processed" }
    }

    analytics_zone = {
      bucket                = var.data_lake_bucket_name
      comment               = "Analytics zone — aggregated and denormalized datasets for reporting."
      encryption_type       = "SSE_KMS"
      kms_key_arn           = var.results_kms_key_arn
      expected_bucket_owner = var.account_id
      force_destroy         = false
      properties            = { classification = "analytics" }
    }
  }

  # -------------------------------------------------------------------------
  # Named queries
  # -------------------------------------------------------------------------
  named_queries = {
    preview_orders = {
      name        = "preview-orders"
      description = "Preview first 10 rows of the orders table."
      database    = "processed_zone"
      workgroup   = "primary"
      query       = "SELECT * FROM processed_zone.orders LIMIT 10;"
    }

    repair_partitions = {
      name        = "repair-orders-partitions"
      description = "Discover new S3 partitions for the orders table."
      database    = "raw_zone"
      workgroup   = "etl_pipelines"
      query       = "MSCK REPAIR TABLE raw_zone.orders;"
    }

    daily_revenue = {
      name        = "daily-revenue"
      description = "Calculate daily revenue for the last 30 days."
      database    = "analytics_zone"
      workgroup   = "reporting"
      query       = <<-SQL
        SELECT
          DATE(order_ts)                    AS order_date,
          SUM(order_amount)                 AS total_revenue,
          COUNT(DISTINCT order_id)          AS total_orders,
          AVG(order_amount)                 AS avg_order_value
        FROM processed_zone.orders
        WHERE order_ts >= DATE_ADD('day', -30, CURRENT_DATE)
          AND status = 'COMPLETED'
        GROUP BY DATE(order_ts)
        ORDER BY order_date DESC;
      SQL
    }

    top_customers = {
      name        = "top-customers"
      description = "Top 100 customers by lifetime value with latest order date."
      database    = "analytics_zone"
      workgroup   = "reporting"
      query       = <<-SQL
        SELECT
          c.customer_id,
          c.email,
          c.country,
          SUM(o.order_amount)      AS lifetime_value,
          COUNT(o.order_id)        AS total_orders,
          MAX(o.order_ts)          AS last_order_date
        FROM processed_zone.customers c
        JOIN processed_zone.orders o
          ON c.customer_id = o.customer_id
        WHERE o.status = 'COMPLETED'
        GROUP BY c.customer_id, c.email, c.country
        ORDER BY lifetime_value DESC
        LIMIT 100;
      SQL
    }

    optimize_orders = {
      name        = "optimize-orders-iceberg"
      description = "Compact small files in the Iceberg orders table."
      database    = "processed_zone"
      workgroup   = "etl_pipelines"
      query       = "OPTIMIZE processed_zone.orders REWRITE DATA USING BIN_PACK;"
    }

    vacuum_orders = {
      name        = "vacuum-orders-iceberg"
      description = "Remove expired Iceberg snapshots from the orders table."
      database    = "processed_zone"
      workgroup   = "etl_pipelines"
      query       = "VACUUM processed_zone.orders;"
    }

    cost_by_workgroup = {
      name        = "cost-by-workgroup"
      description = "Estimate query costs grouped by workgroup (last 7 days)."
      database    = "raw_zone"
      workgroup   = "primary"
      query       = <<-SQL
        SELECT
          workgroup,
          COUNT(*)                                    AS query_count,
          SUM(data_scanned_in_bytes) / 1e9            AS total_gb_scanned,
          ROUND(SUM(data_scanned_in_bytes) / 1e12 * 5, 4) AS estimated_cost_usd,
          AVG(execution_time_in_millis) / 1000.0      AS avg_duration_secs
        FROM information_schema.__internal_partitions__
        WHERE query_state = 'SUCCEEDED'
          AND submit_date >= DATE_ADD('day', -7, CURRENT_DATE)
        GROUP BY workgroup
        ORDER BY total_gb_scanned DESC;
      SQL
    }

    data_quality_check = {
      name        = "data-quality-null-check"
      description = "Count NULL values in critical columns of the orders table."
      database    = "processed_zone"
      workgroup   = "primary"
      query       = <<-SQL
        SELECT
          COUNT(*)                                         AS total_rows,
          SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)     AS null_order_id,
          SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)  AS null_customer_id,
          SUM(CASE WHEN order_amount IS NULL THEN 1 ELSE 0 END) AS null_order_amount,
          SUM(CASE WHEN order_ts IS NULL THEN 1 ELSE 0 END)     AS null_order_ts,
          ROUND(
            100.0 * SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2
          )                                                AS pct_null_order_id
        FROM processed_zone.orders;
      SQL
    }
  }

  # -------------------------------------------------------------------------
  # Data catalogs
  # -------------------------------------------------------------------------
  data_catalogs = {
    federated_lambda = {
      type        = "LAMBDA"
      description = "Lambda-based federated connector for external database queries."
      parameters = {
        function = var.lambda_connector_arn
      }
      tags = { Catalog = "federated-lambda" }
    }
  }

  # -------------------------------------------------------------------------
  # Prepared statements
  # -------------------------------------------------------------------------
  prepared_statements = {
    get_orders_by_date = {
      workgroup_name  = "primary"
      description     = "Retrieve paginated orders within a date range."
      query_statement = <<-SQL
        SELECT
          order_id,
          customer_id,
          order_amount,
          order_ts,
          status
        FROM processed_zone.orders
        WHERE order_ts BETWEEN ? AND ?
          AND status = ?
        ORDER BY order_ts DESC
        LIMIT ?;
      SQL
    }

    revenue_by_country = {
      workgroup_name  = "reporting"
      description     = "Revenue aggregation for a specific country and month."
      query_statement = <<-SQL
        SELECT
          DATE_TRUNC('month', order_ts) AS month,
          country,
          SUM(order_amount)             AS total_revenue,
          COUNT(DISTINCT order_id)      AS total_orders
        FROM processed_zone.orders o
        JOIN processed_zone.customers c ON o.customer_id = c.customer_id
        WHERE c.country = ?
          AND YEAR(order_ts) = ?
          AND MONTH(order_ts) = ?
        GROUP BY 1, 2
        ORDER BY month;
      SQL
    }

    customer_order_history = {
      workgroup_name  = "primary"
      description     = "Full order history for a given customer ID."
      query_statement = <<-SQL
        SELECT
          o.order_id,
          o.order_amount,
          o.order_ts,
          o.status,
          oi.product_id,
          oi.quantity,
          oi.unit_price
        FROM processed_zone.orders o
        JOIN processed_zone.order_items oi ON o.order_id = oi.order_id
        WHERE o.customer_id = ?
        ORDER BY o.order_ts DESC;
      SQL
    }
  }

  # -------------------------------------------------------------------------
  # Capacity reservations
  # -------------------------------------------------------------------------
  capacity_reservations = {
    etl_reservation = {
      target_dpus           = 48
      workgroup_assignments = ["etl_pipelines"]
    }
  }

  # -------------------------------------------------------------------------
  # IAM
  # -------------------------------------------------------------------------
  results_bucket_arns   = [var.results_bucket_arn]
  data_lake_bucket_arns = [var.data_lake_bucket_arn]
  results_kms_key_arn   = var.results_kms_key_arn
}
