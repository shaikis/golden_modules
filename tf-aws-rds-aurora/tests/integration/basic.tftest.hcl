# Integration test — tf-aws-rds-aurora basic
# command = apply (creates real AWS resources — costs money)
# Prerequisites: AWS credentials, a VPC with private subnets, and a DB subnet group

provider "aws" {
  region = "us-east-1"
}

variables {
  name                    = "tftest-aurora-basic"
  db_subnet_group_name    = "default"
  engine                  = "aurora-postgresql"
  engine_version          = "15.4"
  instance_class          = "db.t3.medium"
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 1
  apply_immediately       = true
  create_monitoring_role  = true
  monitoring_interval     = 60
  cluster_instances = {
    "1" = {}
  }
}

# SKIP_IN_CI
run "basic_aurora_cluster" {
  command = apply

  module {
    source = "../../"
  }

  assert {
    condition     = output.cluster_id != ""
    error_message = "Aurora cluster ID should not be empty after apply."
  }

  assert {
    condition     = output.cluster_endpoint != ""
    error_message = "Aurora cluster endpoint should not be empty after apply."
  }

  assert {
    condition     = output.cluster_arn != ""
    error_message = "Aurora cluster ARN should not be empty after apply."
  }
}
