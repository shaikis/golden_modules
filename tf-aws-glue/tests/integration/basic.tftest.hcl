# Integration tests — tf-aws-glue basic
# command = apply: REAL AWS resources are created, then destroyed.
# Glue Data Catalog databases have no ongoing cost.
#
# Prerequisites:
#   export AWS_ACCESS_KEY_ID="..."
#   export AWS_SECRET_ACCESS_KEY="..."
#   export AWS_DEFAULT_REGION="us-east-1"

# SKIP_IN_CI
run "create_catalog_database" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name_prefix              = "tftest-"
    create_catalog_databases = true
    tags = {
      Environment = "test"
      ManagedBy   = "terraform-test"
    }
    catalog_databases = {
      analytics = {
        description = "Integration test analytics database"
      }
    }
  }

  assert {
    condition     = length(var.catalog_databases) == 1
    error_message = "Expected exactly one catalog database to be configured."
  }
}

# SKIP_IN_CI
run "create_multiple_catalog_databases" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name_prefix              = "tftest-multi-"
    create_catalog_databases = true
    tags = {
      Environment = "test"
    }
    catalog_databases = {
      raw = {
        description = "Raw data landing zone"
      }
      curated = {
        description = "Curated analytics-ready data"
      }
    }
  }

  assert {
    condition     = length(var.catalog_databases) == 2
    error_message = "Expected two catalog databases to be configured."
  }

  assert {
    condition     = var.catalog_databases["raw"].description == "Raw data landing zone"
    error_message = "Expected raw database description to match."
  }
}
