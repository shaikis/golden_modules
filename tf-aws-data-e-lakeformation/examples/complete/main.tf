module "lakeformation" {
  source = "../../"

  # ── IAM ──────────────────────────────────────────────────────────────────────
  create_iam_role = true
  iam_role_name   = "lakeformation-service-role-${var.environment}"

  s3_bucket_arns = [
    "arn:aws:s3:::my-datalake-raw-${var.account_id}",
    "arn:aws:s3:::my-datalake-processed-${var.account_id}",
    "arn:aws:s3:::my-datalake-analytics-${var.account_id}",
  ]

  # ── Admins ───────────────────────────────────────────────────────────────────
  data_lake_admins = [var.admin_role_arn]

  create_database_default_permissions = [
    {
      principal   = "IAM_ALLOWED_PRINCIPALS"
      permissions = ["ALL"]
    },
  ]

  create_table_default_permissions = [
    {
      principal   = "IAM_ALLOWED_PRINCIPALS"
      permissions = ["ALL"]
    },
  ]

  # ── S3 Zones ──────────────────────────────────────────────────────────────────
  data_lake_locations = {
    raw = {
      s3_arn                  = "arn:aws:s3:::my-datalake-raw-${var.account_id}"
      use_service_linked_role = false
      hybrid_access_enabled   = false
    }
    processed = {
      s3_arn                  = "arn:aws:s3:::my-datalake-processed-${var.account_id}"
      use_service_linked_role = false
      hybrid_access_enabled   = false
    }
    analytics = {
      s3_arn                  = "arn:aws:s3:::my-datalake-analytics-${var.account_id}"
      use_service_linked_role = false
      hybrid_access_enabled   = true
    }
  }

  # ── LF-Tags (ABAC) ────────────────────────────────────────────────────────────
  create_lf_tags = true

  lf_tags = {
    department = {
      values = ["finance", "marketing", "engineering", "hr", "operations"]
    }
    sensitivity = {
      values = ["public", "internal", "confidential", "restricted"]
    }
    environment = {
      values = ["prod", "staging", "dev"]
    }
  }

  lf_tag_policies = {
    finance_analyst_database_access = {
      principal     = var.analyst_role_arn
      resource_type = "DATABASE"
      permissions   = ["DESCRIBE"]
      expression = [
        { key = "department", values = ["finance"] },
        { key = "environment", values = ["prod"] },
      ]
    }
    engineering_table_access = {
      principal     = var.engineer_role_arn
      resource_type = "TABLE"
      permissions   = ["SELECT", "DESCRIBE"]
      expression = [
        { key = "department", values = ["engineering"] },
        { key = "sensitivity", values = ["public", "internal"] },
      ]
    }
  }

  # ── Fine-grained Permissions ──────────────────────────────────────────────────
  create_permissions = true

  permissions = {
    # Analyst: read-only on processed database
    analyst_processed_db = {
      principal   = var.analyst_role_arn
      permissions = ["DESCRIBE"]
      database = {
        name = "processed_db"
      }
    }

    # Analyst: SELECT on customer orders table
    analyst_orders_table = {
      principal   = var.analyst_role_arn
      permissions = ["SELECT", "DESCRIBE"]
      table = {
        database_name = "processed_db"
        name          = "customer_orders"
      }
    }

    # Engineer: full table access on raw database
    engineer_raw_db = {
      principal   = var.engineer_role_arn
      permissions = ["CREATE_TABLE", "DESCRIBE", "ALTER", "DROP"]
      database = {
        name = "raw_db"
      }
    }

    # Engineer: all tables in processed_db
    engineer_processed_tables = {
      principal   = var.engineer_role_arn
      permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER"]
      table = {
        database_name = "processed_db"
        wildcard      = true
      }
    }

    # Admin: full permissions
    admin_all_tables = {
      principal                     = var.admin_role_arn
      permissions                   = ["ALL"]
      permissions_with_grant_option = ["ALL"]
      table = {
        database_name = "processed_db"
        wildcard      = true
      }
    }

    # Column-level: analyst can SELECT only non-PII columns (exclude SSN and email)
    analyst_pii_masked_columns = {
      principal   = var.analyst_role_arn
      permissions = ["SELECT"]
      table_with_columns = {
        database_name         = "processed_db"
        name                  = "customer_profiles"
        excluded_column_names = ["ssn", "email", "phone_number", "date_of_birth"]
      }
    }

    # Data location access for the engineer role
    engineer_data_location_raw = {
      principal   = var.engineer_role_arn
      permissions = ["DATA_LOCATION_ACCESS"]
      data_location = {
        arn = "arn:aws:s3:::my-datalake-raw-${var.account_id}"
      }
    }
  }

  # ── Data Cell Filters (Row + Column Security) ─────────────────────────────────
  create_data_filters = true

  data_cell_filters = {
    # Row-level: finance dept sees only their department rows
    finance_department_rows = {
      database_name         = "processed_db"
      table_name            = "transactions"
      name                  = "finance_dept_filter"
      row_filter_expression = "department = 'finance'"
      column_names          = []
    }

    # Row-level: marketing dept isolation
    marketing_department_rows = {
      database_name         = "processed_db"
      table_name            = "transactions"
      name                  = "marketing_dept_filter"
      row_filter_expression = "department = 'marketing'"
    }

    # Column-level: hide PII columns from non-privileged access
    pii_column_filter = {
      database_name         = "processed_db"
      table_name            = "customer_profiles"
      name                  = "pii_redacted_filter"
      excluded_column_names = ["ssn", "email", "phone_number"]
    }
  }

  # ── Resource LF-Tag Assignments ───────────────────────────────────────────────
  create_governed_tables = true

  resource_lf_tags = {
    finance_db_tag = {
      database = {
        name = "finance_db"
      }
      lf_tags = [
        { key = "department", value = "finance" },
        { key = "sensitivity", value = "confidential" },
        { key = "environment", value = "prod" },
      ]
    }
    engineering_table_tag = {
      table = {
        database_name = "raw_db"
        name          = "raw_events"
      }
      lf_tags = [
        { key = "department", value = "engineering" },
        { key = "sensitivity", value = "internal" },
        { key = "environment", value = "prod" },
      ]
    }
  }

  tags = var.tags
}
