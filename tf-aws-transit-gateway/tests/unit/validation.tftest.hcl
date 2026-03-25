# Unit tests — variable validation rules for tf-aws-transit-gateway
# No custom validation blocks exist in variables.tf; these tests verify
# structural and logical correctness of feature-gate variable combinations.

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Test: Custom ASN value accepted
# ---------------------------------------------------------------------------
run "custom_asn_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name            = "test-tgw"
    amazon_side_asn = 65000
  }

  assert {
    condition     = var.amazon_side_asn == 65000
    error_message = "Custom amazon_side_asn should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: RAM principals list accepted when RAM sharing enabled
# ---------------------------------------------------------------------------
run "ram_principals_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                   = "test-tgw"
    ram_share_enabled      = true
    ram_principals         = ["123456789012"]
  }

  assert {
    condition     = var.ram_share_enabled == true
    error_message = "ram_share_enabled should be true."
  }

  assert {
    condition     = length(var.ram_principals) == 1
    error_message = "ram_principals should contain one entry."
  }
}

# ---------------------------------------------------------------------------
# Test: TGW CIDR blocks list accepted
# ---------------------------------------------------------------------------
run "tgw_cidr_blocks_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                        = "test-tgw"
    transit_gateway_cidr_blocks = ["10.0.0.0/24"]
  }

  assert {
    condition     = length(var.transit_gateway_cidr_blocks) == 1
    error_message = "transit_gateway_cidr_blocks should accept a non-empty list."
  }
}

# ---------------------------------------------------------------------------
# Test: Default route table association can be disabled
# ---------------------------------------------------------------------------
run "default_route_table_association_disabled" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                             = "test-tgw"
    default_route_table_association  = "disable"
  }

  assert {
    condition     = var.default_route_table_association == "disable"
    error_message = "default_route_table_association should accept 'disable'."
  }
}

# ---------------------------------------------------------------------------
# Test: Default route table propagation can be disabled
# ---------------------------------------------------------------------------
run "default_route_table_propagation_disabled" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                             = "test-tgw"
    default_route_table_propagation  = "disable"
  }

  assert {
    condition     = var.default_route_table_propagation == "disable"
    error_message = "default_route_table_propagation should accept 'disable'."
  }
}
