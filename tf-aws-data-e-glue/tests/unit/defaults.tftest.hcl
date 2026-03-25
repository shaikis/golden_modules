# unit/defaults.tftest.hcl — tf-aws-data-e-glue
# plan-only: verifies feature-gate defaults and BYO IAM/KMS pattern
# No AWS credentials required; runs entirely as a plan.

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# ---------------------------------------------------------------------------
# Test 1 — minimal config: only a Glue job is planned, no optional resources
# ---------------------------------------------------------------------------
run "minimal_config_plans_only_job" {
  command = plan

  variables {
    jobs = {
      "etl" = {
        script_location = "s3://my-bucket/scripts/etl.py"
      }
    }
  }

  # Core job must be planned
  assert {
    condition     = length(aws_glue_job.this) == 1
    error_message = "Expected exactly one Glue job to be planned."
  }

  # Catalog databases gate defaults to false
  assert {
    condition     = length(aws_glue_catalog_database.this) == 0
    error_message = "create_catalog_databases defaults to false; no databases should be planned."
  }

  # Crawlers gate defaults to false
  assert {
    condition     = length(aws_glue_crawler.this) == 0
    error_message = "create_crawlers defaults to false; no crawlers should be planned."
  }

  # Triggers gate defaults to false
  assert {
    condition     = length(aws_glue_trigger.this) == 0
    error_message = "create_triggers defaults to false; no triggers should be planned."
  }

  # Workflows gate defaults to false
  assert {
    condition     = length(aws_glue_workflow.this) == 0
    error_message = "create_workflows defaults to false; no workflows should be planned."
  }

  # Connections gate defaults to false
  assert {
    condition     = length(aws_glue_connection.this) == 0
    error_message = "create_connections defaults to false; no connections should be planned."
  }

  # Schema registries gate defaults to false
  assert {
    condition     = length(aws_glue_registry.this) == 0
    error_message = "create_schema_registries defaults to false; no registries should be planned."
  }

  # Security configurations gate defaults to false
  assert {
    condition     = length(aws_glue_security_configuration.this) == 0
    error_message = "create_security_configurations defaults to false; no security configs should be planned."
  }
}

# ---------------------------------------------------------------------------
# Test 2 — BYO IAM role suppresses auto-create
# ---------------------------------------------------------------------------
run "byo_iam_role_suppresses_creation" {
  command = plan

  variables {
    jobs = {
      "etl" = {
        script_location = "s3://my-bucket/scripts/etl.py"
        role_arn        = "arn:aws:iam::123456789012:role/test"
      }
    }
    create_service_role = false
  }

  assert {
    condition     = length(aws_iam_role.glue_service) == 0
    error_message = "create_service_role = false should prevent auto-creation of the Glue service role."
  }
}

# ---------------------------------------------------------------------------
# Test 3 — BYO KMS key suppresses catalog encryption resource
# ---------------------------------------------------------------------------
run "byo_kms_key_no_catalog_encryption_resource" {
  command = plan

  variables {
    jobs = {
      "etl" = {
        script_location = "s3://my-bucket/scripts/etl.py"
      }
    }
    kms_key_arns              = ["arn:aws:kms:us-east-1:123456789012:key/abc123"]
    create_catalog_encryption = false
  }

  assert {
    condition     = length(aws_glue_data_catalog_encryption_settings.this) == 0
    error_message = "create_catalog_encryption = false must not create catalog encryption settings."
  }
}

# ---------------------------------------------------------------------------
# Test 4 — tag propagation
# ---------------------------------------------------------------------------
run "tags_propagate_to_job" {
  command = plan

  variables {
    jobs = {
      "etl" = {
        script_location = "s3://my-bucket/scripts/etl.py"
      }
    }
    tags = { Environment = "test", Team = "data-engineering" }
  }

  assert {
    condition     = aws_glue_job.this["etl"].tags["Environment"] == "test"
    error_message = "Environment tag must propagate to the Glue job."
  }
}
