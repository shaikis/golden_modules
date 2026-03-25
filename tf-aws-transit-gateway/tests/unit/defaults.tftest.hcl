# Unit tests — defaults and feature gates for tf-aws-transit-gateway
# Runs as plan-only; no AWS resources are created.

variables {
  name = "test-tgw"
}

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Test: VPC attachments default to empty (no attachments unless specified)
# ---------------------------------------------------------------------------
run "vpc_attachments_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.vpc_attachments == {}
    error_message = "vpc_attachments should default to an empty map."
  }
}

# ---------------------------------------------------------------------------
# Test: Custom route tables default to empty
# ---------------------------------------------------------------------------
run "route_tables_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.tgw_route_tables == {}
    error_message = "tgw_route_tables should default to an empty map."
  }
}

# ---------------------------------------------------------------------------
# Test: Static routes default to empty
# ---------------------------------------------------------------------------
run "static_routes_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.tgw_routes == {}
    error_message = "tgw_routes should default to an empty map."
  }
}

# ---------------------------------------------------------------------------
# Test: VPN attachments default to empty
# ---------------------------------------------------------------------------
run "vpn_attachments_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.vpn_attachments == {}
    error_message = "vpn_attachments should default to an empty map."
  }
}

# ---------------------------------------------------------------------------
# Test: DX gateway attachments default to empty
# ---------------------------------------------------------------------------
run "dx_gateway_attachments_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.dx_gateway_attachments == {}
    error_message = "dx_gateway_attachments should default to an empty map."
  }
}

# ---------------------------------------------------------------------------
# Test: RAM sharing disabled by default
# ---------------------------------------------------------------------------
run "ram_share_disabled_by_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.ram_share_enabled == false
    error_message = "ram_share_enabled should default to false."
  }
}

# ---------------------------------------------------------------------------
# Test: amazon_side_asn defaults to 64512
# ---------------------------------------------------------------------------
run "amazon_side_asn_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.amazon_side_asn == 64512
    error_message = "amazon_side_asn should default to 64512."
  }
}

# ---------------------------------------------------------------------------
# Test: DNS support enabled by default
# ---------------------------------------------------------------------------
run "dns_support_enabled_by_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.dns_support == "enable"
    error_message = "dns_support should default to 'enable'."
  }
}

# ---------------------------------------------------------------------------
# Test: VPN ECMP support enabled by default
# ---------------------------------------------------------------------------
run "vpn_ecmp_enabled_by_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.vpn_ecmp_support == "enable"
    error_message = "vpn_ecmp_support should default to 'enable'."
  }
}

# ---------------------------------------------------------------------------
# Test: Multicast support disabled by default
# ---------------------------------------------------------------------------
run "multicast_disabled_by_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.multicast_support == "disable"
    error_message = "multicast_support should default to 'disable'."
  }
}

# ---------------------------------------------------------------------------
# Test: Auto accept shared attachments disabled by default
# ---------------------------------------------------------------------------
run "auto_accept_disabled_by_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.auto_accept_shared_attachments == "disable"
    error_message = "auto_accept_shared_attachments should default to 'disable'."
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
