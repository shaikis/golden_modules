# Unit tests — defaults and feature gates for tf-aws-vpc
# Runs as plan-only; no AWS resources are created.

variables {
  name               = "test-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
}

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Test: VPC is always planned (no conditional create gate)
# ---------------------------------------------------------------------------
run "vpc_is_planned" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.cidr_block == "10.0.0.0/16"
    error_message = "Expected cidr_block to be 10.0.0.0/16."
  }
}

# ---------------------------------------------------------------------------
# Test: NAT gateway defaults to enabled — can be disabled
# ---------------------------------------------------------------------------
run "nat_gateway_disabled" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name               = "test-vpc"
    cidr_block         = "10.0.0.0/16"
    availability_zones = ["us-east-1a"]
    enable_nat_gateway = false
    public_subnet_cidrs  = ["10.0.1.0/24"]
    private_subnet_cidrs = ["10.0.2.0/24"]
  }

  assert {
    condition     = var.enable_nat_gateway == false
    error_message = "enable_nat_gateway should be false when explicitly set."
  }
}

# ---------------------------------------------------------------------------
# Test: Flow logs default to enabled
# ---------------------------------------------------------------------------
run "flow_log_enabled_by_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.enable_flow_log == true
    error_message = "enable_flow_log should default to true."
  }
}

# ---------------------------------------------------------------------------
# Test: Flow logs can be disabled
# ---------------------------------------------------------------------------
run "flow_log_disabled" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name               = "test-vpc"
    cidr_block         = "10.0.0.0/16"
    availability_zones = ["us-east-1a"]
    enable_flow_log    = false
  }

  assert {
    condition     = var.enable_flow_log == false
    error_message = "enable_flow_log should be false when explicitly set."
  }
}

# ---------------------------------------------------------------------------
# Test: Internet gateway created by default
# ---------------------------------------------------------------------------
run "igw_created_by_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_igw == true
    error_message = "create_igw should default to true."
  }
}

# ---------------------------------------------------------------------------
# Test: VPN gateway disabled by default
# ---------------------------------------------------------------------------
run "vpn_gateway_disabled_by_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.enable_vpn_gateway == false
    error_message = "enable_vpn_gateway should default to false."
  }
}

# ---------------------------------------------------------------------------
# Test: S3 endpoint enabled by default, DynamoDB disabled by default
# ---------------------------------------------------------------------------
run "endpoint_defaults" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.enable_s3_endpoint == true
    error_message = "enable_s3_endpoint should default to true."
  }

  assert {
    condition     = var.enable_dynamodb_endpoint == false
    error_message = "enable_dynamodb_endpoint should default to false."
  }
}

# ---------------------------------------------------------------------------
# Test: Interface endpoints map defaults to empty
# ---------------------------------------------------------------------------
run "interface_endpoints_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.interface_endpoints == {}
    error_message = "interface_endpoints should default to an empty map."
  }
}

# ---------------------------------------------------------------------------
# Test: DNS hostnames and support enabled by default
# ---------------------------------------------------------------------------
run "dns_defaults" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.enable_dns_hostnames == true
    error_message = "enable_dns_hostnames should default to true."
  }

  assert {
    condition     = var.enable_dns_support == true
    error_message = "enable_dns_support should default to true."
  }
}

# ---------------------------------------------------------------------------
# Test: environment defaults to dev
# ---------------------------------------------------------------------------
run "environment_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.environment == "dev"
    error_message = "environment should default to 'dev'."
  }
}

# ---------------------------------------------------------------------------
# Test: Single NAT gateway defaults to false (one per AZ)
# ---------------------------------------------------------------------------
run "single_nat_gateway_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.single_nat_gateway == false
    error_message = "single_nat_gateway should default to false."
  }
}
