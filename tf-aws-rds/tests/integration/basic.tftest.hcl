# Integration test — tf-aws-rds basic
# command = apply (creates real AWS resources — costs money)
# Prerequisites: AWS credentials, a VPC with private subnets, and a DB subnet group

provider "aws" {
  region = "us-east-1"
}

variables {
  name                    = "tftest-rds-basic"
  db_subnet_group_name    = "default"
  engine                  = "postgres"
  engine_version          = "15.5"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  skip_final_snapshot     = true
  deletion_protection     = false
  multi_az                = false
  backup_retention_period = 1
  create_monitoring_role  = true
  monitoring_interval     = 60
  apply_immediately       = true
}

# SKIP_IN_CI
run "basic_rds_instance" {
  command = apply

  module {
    source = "../../"
  }

  assert {
    condition     = output.db_instance_identifier != ""
    error_message = "DB instance identifier should not be empty after apply."
  }

  assert {
    condition     = output.db_instance_endpoint != ""
    error_message = "DB instance endpoint should not be empty after apply."
  }

  assert {
    condition     = output.db_instance_arn != ""
    error_message = "DB instance ARN should not be empty after apply."
  }
}
