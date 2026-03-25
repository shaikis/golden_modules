# Integration tests — basic VPN (no resources) for tf-aws-vpn
# With all feature flags disabled this module creates no AWS resources,
# confirming that the minimal invocation safely no-ops.
# Requires valid AWS credentials in the environment.

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Test: Deploy module with all features disabled — zero cost no-op # SKIP_IN_CI
# ---------------------------------------------------------------------------
run "all_features_disabled_apply" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name                    = "tftest-vpn"
    enable_site_to_site_vpn = false
    enable_client_vpn       = false
    create_vpn_gateway      = false
    environment             = "test"

    tags = {
      ManagedBy = "terraform-test"
    }
  }

  # No VPN gateway created
  assert {
    condition     = module.this.vpn_gateway_id == null
    error_message = "vpn_gateway_id should be null when create_vpn_gateway = false."
  }

  # No customer gateways created
  assert {
    condition     = length(module.this.customer_gateway_ids) == 0
    error_message = "No customer gateways should be created when customer_gateways is empty."
  }

  # No VPN connections created
  assert {
    condition     = length(module.this.vpn_connection_ids) == 0
    error_message = "No VPN connections should be created when no customer_gateways are specified."
  }

  # No client VPN endpoint
  assert {
    condition     = module.this.client_vpn_endpoint_id == null
    error_message = "client_vpn_endpoint_id should be null when enable_client_vpn = false."
  }
}
