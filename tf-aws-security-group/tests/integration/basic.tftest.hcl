# Integration tests — basic security group for tf-aws-security-group
# Creates real AWS resources; always destroyed after the run block completes.
# Requires valid AWS credentials and an existing VPC in the environment.

provider "aws" {
  region = "us-east-1"
}

# Fetch the default VPC to avoid creating one in integration tests
data "aws_vpc" "default" {
  default = true
}

# ---------------------------------------------------------------------------
# Test: Create a minimal security group with one ingress rule # SKIP_IN_CI
# ---------------------------------------------------------------------------
run "basic_security_group_apply" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name        = "tftest-sg"
    vpc_id      = data.aws_vpc.default.id
    description = "Terraform test security group"
    environment = "test"

    ingress_rules = {
      https = {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
        description = "Allow HTTPS from RFC-1918"
      }
    }

    egress_rules = {
      all_out = {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound"
      }
    }

    tags = {
      ManagedBy = "terraform-test"
    }
  }

  # Security group ID is non-empty
  assert {
    condition     = length(module.this.security_group_id) > 3
    error_message = "security_group_id should be a non-empty identifier."
  }

  # ARN contains 'security-group'
  assert {
    condition     = can(regex("security-group", module.this.security_group_arn))
    error_message = "security_group_arn should contain 'security-group'."
  }

  # Name matches input
  assert {
    condition     = module.this.security_group_name == "tftest-sg"
    error_message = "security_group_name should match the input name."
  }
}
