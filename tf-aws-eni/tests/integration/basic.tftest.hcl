# Integration tests — basic ENI creation for tf-aws-eni
# Creates a single ENI in the default VPC's first available subnet.
# Requires valid AWS credentials in the environment.

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ---------------------------------------------------------------------------
# Test: Create a single bare ENI with no EIP or attachment # SKIP_IN_CI
# ---------------------------------------------------------------------------
run "basic_eni_apply" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name        = "tftest-eni"
    environment = "test"

    network_interfaces = {
      primary = {
        subnet_id         = data.aws_subnets.default.ids[0]
        source_dest_check = true
        description       = "Terraform test ENI"
      }
    }

    tags = {
      ManagedBy = "terraform-test"
    }
  }

  # ENI ID map is non-empty
  assert {
    condition     = length(module.this.eni_ids) == 1
    error_message = "Expected exactly one ENI to be created."
  }

  # ENI key matches input
  assert {
    condition     = contains(keys(module.this.eni_ids), "primary")
    error_message = "eni_ids map should contain key 'primary'."
  }

  # Private IP is assigned (DHCP)
  assert {
    condition     = contains(keys(module.this.eni_private_ips), "primary")
    error_message = "eni_private_ips should contain an entry for 'primary'."
  }

  # No EIPs allocated (eip block not specified)
  assert {
    condition     = length(module.this.eip_public_ips) == 0
    error_message = "No EIPs should be allocated when eip block is not specified."
  }
}
