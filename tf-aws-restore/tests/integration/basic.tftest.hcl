# SKIP_IN_CI
# Integration test — tf-aws-restore
# command = apply; creates an IAM role and a Backup restore testing plan.
# Cost: IAM roles and Backup restore testing plans are free.
# Destroy immediately after testing.
# Set AWS_PROFILE / AWS credentials before running.

provider "aws" {
  region = "us-east-1"
}

variables {
  name            = "tftest-restore-basic"
  environment     = "test"
  create_iam_role = true

  restore_testing_plans = {
    weekly_ec2 = {
      algorithm            = "LATEST_WITHIN_WINDOW"
      recovery_point_types = ["SNAPSHOT"]
      include_vaults       = ["*"]
      schedule_expression  = "cron(0 6 ? * SUN *)"
      start_window_hours   = 2
      tags = {
        ManagedBy = "terraform-test"
      }
    }
  }

  tags = {
    ManagedBy   = "terraform-test"
    Environment = "test"
  }
}

run "create_restore_plan" {
  command = apply

  module {
    source = "../../"
  }

  assert {
    condition     = output.iam_role_arn != null && output.iam_role_arn != ""
    error_message = "Expected iam_role_arn to be set after apply."
  }

  assert {
    condition     = length(output.restore_testing_plan_names) == 1
    error_message = "Expected exactly 1 restore testing plan to be created."
  }

  assert {
    condition     = output.restore_testing_plan_names["weekly_ec2"] != ""
    error_message = "Expected restore testing plan 'weekly_ec2' to have a name."
  }
}
