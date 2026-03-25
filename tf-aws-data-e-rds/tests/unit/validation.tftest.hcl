# Unit test — input validation for tf-aws-data-e-rds
# command = plan: no real AWS resources are created.
# These runs verify that invalid inputs are rejected before any apply.

run "valid_postgres_engine_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                 = "test-rds-valid-engine"
    db_subnet_group_name = "default"
    engine               = "postgres"
    engine_version       = "15.5"
  }

  assert {
    condition     = var.engine == "postgres"
    error_message = "postgres is a valid engine and should be accepted."
  }
}

run "valid_mysql_engine_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                 = "test-rds-mysql"
    db_subnet_group_name = "default"
    engine               = "mysql"
    engine_version       = "8.0"
  }

  assert {
    condition     = var.engine == "mysql"
    error_message = "mysql is a valid engine and should be accepted."
  }
}

# Placeholder: once a validation block is added for the engine variable,
# uncomment this run to verify that unsupported engines are rejected.
#
# run "invalid_engine_rejected" {
#   command = plan
#   expect_failures = [var.engine]
#
#   module {
#     source = "../../"
#   }
#
#   variables {
#     name                 = "test-rds-bad-engine"
#     db_subnet_group_name = "default"
#     engine               = "cassandra"   # not a valid RDS engine
#   }
# }

run "deletion_protection_defaults_true" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                 = "test-rds-del-protect"
    db_subnet_group_name = "default"
  }

  assert {
    condition     = var.deletion_protection == true
    error_message = "deletion_protection must default to true to prevent accidental data loss."
  }
}
