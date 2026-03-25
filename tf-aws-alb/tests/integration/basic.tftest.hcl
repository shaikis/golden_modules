# SKIP_IN_CI
# Integration test — tf-aws-alb
# command = apply; requires real VPC and subnets in the target AWS account.
# Costs: ALB ~$0.008/LCU-hour + $0.0225/hour base.
# Set AWS_PROFILE / AWS credentials before running.

provider "aws" {
  region = "us-east-1"
}

# These locals reference pre-existing networking resources that must exist in
# the target account before running this test.
variables {
  name    = "tftest-alb-basic"
  vpc_id  = "REPLACE_WITH_REAL_VPC_ID"
  subnets = ["REPLACE_WITH_REAL_SUBNET_1", "REPLACE_WITH_REAL_SUBNET_2"]

  internal                   = false
  load_balancer_type         = "application"
  enable_deletion_protection = false

  tags = {
    ManagedBy   = "terraform-test"
    Environment = "test"
  }
}

run "create_alb" {
  command = apply

  module {
    source = "../../"
  }

  assert {
    condition     = output.lb_arn != ""
    error_message = "Expected lb_arn to be non-empty after apply."
  }

  assert {
    condition     = output.lb_dns_name != ""
    error_message = "Expected lb_dns_name to be non-empty after apply."
  }
}
