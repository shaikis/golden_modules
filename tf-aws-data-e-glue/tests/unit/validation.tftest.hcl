# unit/validation.tftest.hcl — tf-aws-data-e-glue
# plan-only: verifies variable validation rules reject invalid inputs.
# Each run block expects an error (expect_failures).

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# ---------------------------------------------------------------------------
# Test 1 — create_crawlers = true but crawlers map is empty
#           (guards the dependency: gate enabled with no config)
# ---------------------------------------------------------------------------
run "crawlers_gate_with_empty_map_fails" {
  command = plan

  variables {
    jobs = {
      "etl" = {
        script_location = "s3://my-bucket/scripts/etl.py"
      }
    }
    create_crawlers = true
    crawlers        = {}
  }

  expect_failures = [
    var.crawlers,
  ]
}

# ---------------------------------------------------------------------------
# Test 2 — create_security_configurations = true requires kms_key_arns
# ---------------------------------------------------------------------------
run "security_config_gate_requires_kms_key" {
  command = plan

  variables {
    jobs = {
      "etl" = {
        script_location = "s3://my-bucket/scripts/etl.py"
      }
    }
    create_security_configurations = true
    security_configurations = {
      "main" = {
        s3_kms_key_arn             = null
        cloudwatch_kms_key_arn     = null
        bookmark_kms_key_arn       = null
      }
    }
    kms_key_arns = []
  }

  expect_failures = [
    var.kms_key_arns,
  ]
}

# ---------------------------------------------------------------------------
# Test 3 — create_catalog_databases = true but catalog_databases is empty
# ---------------------------------------------------------------------------
run "catalog_databases_gate_with_empty_map_fails" {
  command = plan

  variables {
    jobs = {
      "etl" = {
        script_location = "s3://my-bucket/scripts/etl.py"
      }
    }
    create_catalog_databases = true
    catalog_databases        = {}
  }

  expect_failures = [
    var.catalog_databases,
  ]
}

# ---------------------------------------------------------------------------
# Test 4 — job script_location must be a valid S3 URI (starts with s3://)
# ---------------------------------------------------------------------------
run "job_script_location_must_be_s3_uri" {
  command = plan

  variables {
    jobs = {
      "etl" = {
        script_location = "/local/path/etl.py"
      }
    }
  }

  expect_failures = [
    var.jobs,
  ]
}
