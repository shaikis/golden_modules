# Integration test — tf-aws-data-e-glue
# Glue catalog databases are free (jobs only cost when executed).
# Uses command = apply: catalog databases have no standing cost.

run "glue_catalog_database_apply" {
  # SKIP_IN_CI
  # Cost: Glue catalog databases are free (jobs only cost when executed)
  command = apply

  variables {
    name_prefix = "inttest"

    create_catalog_databases = true

    catalog_databases = {
      basic = {
        description = "Integration test Glue catalog database"
        parameters  = {}
      }
    }

    create_crawlers            = false
    create_triggers            = false
    create_workflows           = false
    create_connections         = false
    create_schema_registries   = false
    create_security_configurations = false
    create_catalog_encryption  = false
    create_iam_role            = false

    jobs = {}

    tags = {
      Environment = "integration-test"
      ManagedBy   = "terraform-test"
    }
  }

  assert {
    condition     = length(output.catalog_database_names) == 1
    error_message = "Expected exactly one catalog database name."
  }

  assert {
    condition     = output.catalog_database_names["basic"] != null && output.catalog_database_names["basic"] != ""
    error_message = "catalog_database_names[\"basic\"] must be a non-empty string."
  }

  assert {
    condition     = output.catalog_database_arns["basic"] != null && output.catalog_database_arns["basic"] != ""
    error_message = "catalog_database_arns[\"basic\"] must be a non-empty ARN."
  }
}
