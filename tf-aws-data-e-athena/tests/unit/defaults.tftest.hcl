# unit/defaults.tftest.hcl — tf-aws-data-e-athena
# plan-only: verifies gate defaults and BYO KMS pattern
# No AWS credentials required; runs entirely as a plan.

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# ---------------------------------------------------------------------------
# Test 1 — minimal config: only a workgroup is planned
# ---------------------------------------------------------------------------
run "minimal_config_plans_only_workgroup" {
  command = plan

  variables {
    workgroups = {
      "primary" = {
        result_configuration = {
          output_location = "s3://my-results-bucket/athena/"
        }
      }
    }
  }

  # Workgroup must be planned
  assert {
    condition     = length(aws_athena_workgroup.this) == 1
    error_message = "Expected exactly one Athena workgroup to be planned."
  }

  # Databases map defaults to empty — no databases planned
  assert {
    condition     = length(aws_athena_database.this) == 0
    error_message = "databases defaults to empty; no Athena databases should be planned."
  }

  # Named queries map defaults to empty
  assert {
    condition     = length(aws_athena_named_query.this) == 0
    error_message = "named_queries defaults to empty; no named queries should be planned."
  }

  # Data catalogs map defaults to empty
  assert {
    condition     = length(aws_athena_data_catalog.this) == 0
    error_message = "data_catalogs defaults to empty; no data catalogs should be planned."
  }

  # Prepared statements map defaults to empty
  assert {
    condition     = length(aws_athena_prepared_statement.this) == 0
    error_message = "prepared_statements defaults to empty; no prepared statements should be planned."
  }

  # Capacity reservations map defaults to empty
  assert {
    condition     = length(aws_athena_capacity_reservation.this) == 0
    error_message = "capacity_reservations defaults to empty; no capacity reservations should be planned."
  }
}

# ---------------------------------------------------------------------------
# Test 2 — BYO KMS key for query result encryption
# ---------------------------------------------------------------------------
run "byo_kms_key_used_for_results_encryption" {
  command = plan

  variables {
    workgroups = {
      "primary" = {
        result_configuration = {
          output_location = "s3://my-results-bucket/athena/"
          encryption_type = "SSE_KMS"
          kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/abc123"
        }
      }
    }
    results_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abc123"
  }

  # BYO KMS — no aws_kms_key resource should be created
  assert {
    condition     = length(aws_kms_key.this) == 0
    error_message = "When kms_key_arn is provided, the module must not create a KMS key."
  }
}

# ---------------------------------------------------------------------------
# Test 3 — workgroup with SSE_S3 (no KMS) plans without error
# ---------------------------------------------------------------------------
run "workgroup_with_sse_s3_encryption" {
  command = plan

  variables {
    workgroups = {
      "primary" = {
        result_configuration = {
          output_location = "s3://my-results-bucket/athena/"
          encryption_type = "SSE_S3"
        }
      }
    }
  }

  assert {
    condition     = length(aws_athena_workgroup.this) == 1
    error_message = "Workgroup with SSE_S3 encryption should plan successfully."
  }
}

# ---------------------------------------------------------------------------
# Test 4 — tag propagation
# ---------------------------------------------------------------------------
run "tags_propagate_to_workgroup" {
  command = plan

  variables {
    workgroups = {
      "primary" = {
        result_configuration = {
          output_location = "s3://my-results-bucket/athena/"
        }
      }
    }
    tags = { Environment = "test", Team = "data-engineering" }
  }

  assert {
    condition     = aws_athena_workgroup.this["primary"].tags["Environment"] == "test"
    error_message = "Environment tag must propagate to the Athena workgroup."
  }
}
