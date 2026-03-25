# Unit tests — defaults and feature gates for tf-aws-vpn
# Runs as plan-only; no AWS resources are created.

variables {
  name = "test-vpn"
}

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Test: Site-to-site VPN disabled by default
# ---------------------------------------------------------------------------
run "site_to_site_disabled_by_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.enable_site_to_site_vpn == false
    error_message = "enable_site_to_site_vpn should default to false."
  }
}

# ---------------------------------------------------------------------------
# Test: Client VPN disabled by default
# ---------------------------------------------------------------------------
run "client_vpn_disabled_by_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.enable_client_vpn == false
    error_message = "enable_client_vpn should default to false."
  }
}

# ---------------------------------------------------------------------------
# Test: Virtual private gateway disabled by default
# ---------------------------------------------------------------------------
run "vpn_gateway_disabled_by_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_vpn_gateway == false
    error_message = "create_vpn_gateway should default to false."
  }
}

# ---------------------------------------------------------------------------
# Test: Customer gateways map defaults to empty
# ---------------------------------------------------------------------------
run "customer_gateways_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.customer_gateways == {}
    error_message = "customer_gateways should default to an empty map."
  }
}

# ---------------------------------------------------------------------------
# Test: Client VPN split tunnel enabled by default
# ---------------------------------------------------------------------------
run "client_vpn_split_tunnel_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.client_vpn_split_tunnel == true
    error_message = "client_vpn_split_tunnel should default to true."
  }
}

# ---------------------------------------------------------------------------
# Test: Client VPN transport protocol defaults to udp
# ---------------------------------------------------------------------------
run "client_vpn_transport_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.client_vpn_transport_protocol == "udp"
    error_message = "client_vpn_transport_protocol should default to 'udp'."
  }
}

# ---------------------------------------------------------------------------
# Test: Client VPN port defaults to 443
# ---------------------------------------------------------------------------
run "client_vpn_port_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.client_vpn_vpn_port == 443
    error_message = "client_vpn_vpn_port should default to 443."
  }
}

# ---------------------------------------------------------------------------
# Test: Client VPN session timeout defaults to 12 hours
# ---------------------------------------------------------------------------
run "client_vpn_session_timeout_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.client_vpn_session_timeout_hours == 12
    error_message = "client_vpn_session_timeout_hours should default to 12."
  }
}

# ---------------------------------------------------------------------------
# Test: VPN gateway Amazon side ASN defaults to 64512
# ---------------------------------------------------------------------------
run "vpn_gateway_asn_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.vpn_gateway_amazon_side_asn == 64512
    error_message = "vpn_gateway_amazon_side_asn should default to 64512."
  }
}

# ---------------------------------------------------------------------------
# Test: Propagating VGW route tables defaults to empty
# ---------------------------------------------------------------------------
run "propagating_route_tables_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.propagating_vgw_route_tables == []
    error_message = "propagating_vgw_route_tables should default to an empty list."
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
