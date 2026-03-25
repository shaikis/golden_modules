# SKIP_IN_CI
# Integration test — tf-aws-efs
# command = apply; creates a real EFS file system.
# Cost: ~$0.30/GB-month (Elastic throughput). Destroy immediately after testing.
# Set AWS_PROFILE / AWS credentials before running.

provider "aws" {
  region = "us-east-1"
}

variables {
  name        = "tftest-efs-basic"
  environment = "test"

  # Disable security group creation and mount targets to minimise dependencies
  create_security_group = false
  subnet_ids            = []

  throughput_mode      = "elastic"
  performance_mode     = "generalPurpose"
  enable_backup_policy = false
  enable_replication   = false

  tags = {
    ManagedBy   = "terraform-test"
    Environment = "test"
  }
}

run "create_efs" {
  command = apply

  module {
    source = "../../"
  }

  assert {
    condition     = output.file_system_id != null && output.file_system_id != ""
    error_message = "Expected file_system_id to be set after apply."
  }

  assert {
    condition     = output.file_system_arn != null && output.file_system_arn != ""
    error_message = "Expected file_system_arn to be set after apply."
  }

  assert {
    condition     = output.dns_name != null && output.dns_name != ""
    error_message = "Expected dns_name to be set after apply."
  }
}
