# Unit tests — variable validation rules for tf-aws-vpn
# Verifies structural correctness and feature-gate combinations.

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Test: Customer gateway with BGP ASN and IP address accepted
# ---------------------------------------------------------------------------
run "customer_gateway_config_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                   = "test-vpn"
    enable_site_to_site_vpn = true
    transit_gateway_id     = "tgw-00000000000000000"
    customer_gateways = {
      onprem = {
        bgp_asn    = 65000
        ip_address = "203.0.113.1"
      }
    }
  }

  assert {
    condition     = contains(keys(var.customer_gateways), "onprem")
    error_message = "customer_gateways should accept an 'onprem' entry."
  }

  assert {
    condition     = var.customer_gateways["onprem"].bgp_asn == 65000
    error_message = "BGP ASN should be 65000."
  }
}

# ---------------------------------------------------------------------------
# Test: Static routes only mode accepted in customer gateway
# ---------------------------------------------------------------------------
run "static_routes_only_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                   = "test-vpn"
    enable_site_to_site_vpn = true
    transit_gateway_id     = "tgw-00000000000000000"
    customer_gateways = {
      onprem = {
        bgp_asn            = 65000
        ip_address         = "203.0.113.1"
        static_routes_only = true
        static_routes      = ["192.168.1.0/24"]
      }
    }
  }

  assert {
    condition     = var.customer_gateways["onprem"].static_routes_only == true
    error_message = "static_routes_only should be accepted as true."
  }
}

# ---------------------------------------------------------------------------
# Test: Client VPN authorization rules default to allow-all-vpc
# ---------------------------------------------------------------------------
run "client_vpn_auth_rules_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-vpn"
  }

  assert {
    condition     = contains(keys(var.client_vpn_authorization_rules), "all_vpc")
    error_message = "client_vpn_authorization_rules should contain a default 'all_vpc' rule."
  }
}

# ---------------------------------------------------------------------------
# Test: Additional client VPN routes accepted
# ---------------------------------------------------------------------------
run "client_vpn_additional_routes_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-vpn"
    client_vpn_additional_routes = {
      shared_services = {
        destination_cidr     = "172.16.0.0/12"
        target_vpc_subnet_id = "subnet-00000000000000000"
        description          = "Route to shared services"
      }
    }
  }

  assert {
    condition     = contains(keys(var.client_vpn_additional_routes), "shared_services")
    error_message = "Additional client VPN routes should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: Client VPN DNS servers list accepted
# ---------------------------------------------------------------------------
run "client_vpn_dns_servers_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                   = "test-vpn"
    client_vpn_dns_servers = ["8.8.8.8", "8.8.4.4"]
  }

  assert {
    condition     = length(var.client_vpn_dns_servers) == 2
    error_message = "client_vpn_dns_servers should accept a two-entry list."
  }
}
