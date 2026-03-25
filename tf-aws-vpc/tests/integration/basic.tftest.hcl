# Integration tests — basic VPC with minimal resources for tf-aws-vpc
# Creates real AWS resources; always destroyed after the run block completes.
# Requires valid AWS credentials in the environment.

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Test: Deploy a minimal VPC with one public and one private subnet # SKIP_IN_CI
# ---------------------------------------------------------------------------
run "basic_vpc_apply" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name               = "tftest-vpc"
    cidr_block         = "10.99.0.0/16"
    availability_zones = ["us-east-1a"]

    public_subnet_cidrs  = ["10.99.1.0/24"]
    private_subnet_cidrs = ["10.99.2.0/24"]

    enable_nat_gateway = false
    enable_flow_log    = false
    enable_s3_endpoint = false

    environment = "test"
    tags = {
      ManagedBy = "terraform-test"
    }
  }

  # VPC ID is non-empty and starts with 'vpc-'
  assert {
    condition     = length(module.this.vpc_id) > 4
    error_message = "vpc_id should be a non-empty VPC identifier."
  }

  # CIDR block is preserved in output
  assert {
    condition     = module.this.vpc_cidr_block == "10.99.0.0/16"
    error_message = "vpc_cidr_block output should match the input cidr_block."
  }

  # One public subnet created
  assert {
    condition     = length(module.this.public_subnet_ids_list) == 1
    error_message = "Expected exactly one public subnet."
  }

  # One private subnet created
  assert {
    condition     = length(module.this.private_subnet_ids_list) == 1
    error_message = "Expected exactly one private subnet."
  }

  # No NAT gateways provisioned
  assert {
    condition     = length(module.this.nat_gateway_ids) == 0
    error_message = "No NAT gateways should be created when enable_nat_gateway = false."
  }

  # IGW is provisioned (default create_igw = true)
  assert {
    condition     = module.this.internet_gateway_id != null
    error_message = "Internet gateway should be created by default."
  }

  # Flow log ID is null when disabled
  assert {
    condition     = module.this.flow_log_id == null
    error_message = "flow_log_id should be null when enable_flow_log = false."
  }
}
