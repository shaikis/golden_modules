# Integration tests — basic S3 Gateway endpoint for tf-aws-vpc-endpoints
# Creates a single Gateway endpoint (no ENI, no cost beyond normal S3 usage).
# Requires valid AWS credentials and an existing VPC with route tables.

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_route_tables" "default" {
  vpc_id = data.aws_vpc.default.id
}

# ---------------------------------------------------------------------------
# Test: Create a single S3 Gateway endpoint # SKIP_IN_CI
# ---------------------------------------------------------------------------
run "s3_gateway_endpoint_apply" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name        = "tftest-endpoints"
    vpc_id      = data.aws_vpc.default.id
    environment = "test"

    default_route_table_ids = data.aws_route_tables.default.ids

    endpoints = {
      s3 = {
        service_name      = "com.amazonaws.us-east-1.s3"
        vpc_endpoint_type = "Gateway"
        route_table_ids   = data.aws_route_tables.default.ids
      }
    }

    tags = {
      ManagedBy = "terraform-test"
    }
  }

  # Gateway endpoint ID is created
  assert {
    condition     = length(module.this.gateway_endpoint_ids) == 1
    error_message = "Expected exactly one gateway endpoint to be created."
  }

  # No interface endpoints created
  assert {
    condition     = length(module.this.interface_endpoint_ids) == 0
    error_message = "No interface endpoints should be created in this test."
  }

  # Gateway endpoint key is 's3'
  assert {
    condition     = contains(keys(module.this.gateway_endpoint_ids), "s3")
    error_message = "Gateway endpoint map should contain key 's3'."
  }
}
