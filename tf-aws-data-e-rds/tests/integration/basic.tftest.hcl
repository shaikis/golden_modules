# Integration test — basic MySQL RDS instance for tf-aws-data-e-rds
# command = apply: creates a real RDS instance in AWS.
# SKIP_IN_CI

# Prerequisites:
#   export AWS_ACCESS_KEY_ID="..."
#   export AWS_SECRET_ACCESS_KEY="..."
#   export AWS_DEFAULT_REGION="us-east-1"
#   A DB subnet group named "default" (or override db_subnet_group_name) must
#   exist in the target VPC.
#
# Cost: db.t3.micro MySQL ~$0.017/hour. Destroy promptly after testing.

# Provider configuration for the integration environment.
provider "aws" {
  region = "us-east-1"
}

run "create_mysql_db_t3_micro" {
  # SKIP_IN_CI
  command = apply

  module {
    source = "../../"
  }

  variables {
    name                 = "integ-rds-test"
    environment          = "test"
    db_subnet_group_name = "default"

    engine         = "mysql"
    engine_version = "8.0"
    instance_class = "db.t3.micro"

    db_name  = "integtest"
    username = "dbadmin"

    # Let RDS manage the master password in Secrets Manager.
    manage_master_user_password = true

    allocated_storage     = 20
    max_allocated_storage = 50
    storage_type          = "gp3"
    storage_encrypted     = true

    # BYO encryption: kms_key_id = null uses AWS-managed key.
    kms_key_id = null

    multi_az             = false
    publicly_accessible  = false
    deletion_protection  = false
    skip_final_snapshot  = true

    backup_retention_period = 1

    enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

    tags = {
      Purpose = "integration-test"
    }
  }

  assert {
    condition     = output.db_instance_identifier != ""
    error_message = "db_instance_identifier output must be set after a successful apply."
  }
}
