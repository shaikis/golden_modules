# ===========================================================================
# SITE-TO-SITE VPN
# ===========================================================================

# ---------------------------------------------------------------------------
# Virtual Private Gateway (when not using TGW)
# ---------------------------------------------------------------------------
resource "aws_vpn_gateway" "this" {
  count           = var.create_vpn_gateway ? 1 : 0
  vpc_id          = var.vpc_id
  amazon_side_asn = var.vpn_gateway_amazon_side_asn

  tags = merge(local.tags, { Name = "${local.name}-vgw" })
}

resource "aws_vpn_gateway_route_propagation" "this" {
  for_each = var.create_vpn_gateway ? toset(var.propagating_vgw_route_tables) : []

  vpn_gateway_id = aws_vpn_gateway.this[0].id
  route_table_id = each.value
}

# ---------------------------------------------------------------------------
# Customer Gateways + VPN Connections
# ---------------------------------------------------------------------------
resource "aws_customer_gateway" "this" {
  for_each = var.enable_site_to_site_vpn ? var.customer_gateways : {}

  bgp_asn         = each.value.bgp_asn
  ip_address      = each.value.ip_address
  type            = each.value.type
  device_name     = each.value.device_name
  certificate_arn = each.value.certificate_arn

  tags = merge(local.tags, { Name = "${local.name}-cgw-${each.key}" })
}

resource "aws_vpn_connection" "this" {
  for_each = var.enable_site_to_site_vpn ? var.customer_gateways : {}

  customer_gateway_id                     = aws_customer_gateway.this[each.key].id
  type                                    = each.value.type
  static_routes_only                      = each.value.static_routes_only
  local_ipv4_network_cidr                 = each.value.local_ipv4_network_cidr
  remote_ipv4_network_cidr                = each.value.remote_ipv4_network_cidr
  outside_ip_address_type                 = each.value.outside_ip_address_type
  transport_transit_gateway_attachment_id = each.value.transport_transit_gateway_attachment_id

  # Gateway: TGW or VGW
  transit_gateway_id = var.transit_gateway_id
  vpn_gateway_id     = var.transit_gateway_id == null && var.create_vpn_gateway ? aws_vpn_gateway.this[0].id : null

  # Tunnel 1
  tunnel1_inside_cidr                  = each.value.tunnel1_inside_cidr
  tunnel1_preshared_key                = each.value.tunnel1_preshared_key
  tunnel1_startup_action               = each.value.tunnel1_startup_action
  tunnel1_ike_versions                 = each.value.tunnel1_ike_versions
  tunnel1_phase1_dh_group_numbers      = each.value.tunnel1_phase1_dh_group_numbers
  tunnel1_phase1_encryption_algorithms = each.value.tunnel1_phase1_encryption_algorithms
  tunnel1_phase1_integrity_algorithms  = each.value.tunnel1_phase1_integrity_algorithms
  tunnel1_phase2_dh_group_numbers      = each.value.tunnel1_phase2_dh_group_numbers
  tunnel1_phase2_encryption_algorithms = each.value.tunnel1_phase2_encryption_algorithms
  tunnel1_phase2_integrity_algorithms  = each.value.tunnel1_phase2_integrity_algorithms

  # Tunnel 2
  tunnel2_inside_cidr    = each.value.tunnel2_inside_cidr
  tunnel2_preshared_key  = each.value.tunnel2_preshared_key
  tunnel2_startup_action = each.value.tunnel2_startup_action
  tunnel2_ike_versions   = each.value.tunnel2_ike_versions

  tags = merge(local.tags, { Name = "${local.name}-vpn-${each.key}" })

  lifecycle {
    ignore_changes = [tunnel1_preshared_key, tunnel2_preshared_key, tags["CreatedDate"]]
  }
}

# Static routes for VPN connections
resource "aws_vpn_connection_route" "this" {
  for_each = {
    for item in flatten([
      for cgw_key, cgw_val in var.customer_gateways : [
        for route in cgw_val.static_routes : {
          key     = "${cgw_key}-${replace(route, "/", "_")}"
          cgw_key = cgw_key
          cidr    = route
        }
      ]
    ]) : item.key => item
    if var.enable_site_to_site_vpn && cgw_val.static_routes_only
  }

  vpn_connection_id      = aws_vpn_connection.this[each.value.cgw_key].id
  destination_cidr_block = each.value.cidr
}

# ===========================================================================
# CLIENT VPN
# ===========================================================================

# ---------------------------------------------------------------------------
# CloudWatch Log Group for Client VPN
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "client_vpn" {
  count = var.enable_client_vpn ? 1 : 0

  name              = coalesce(var.client_vpn_cloudwatch_log_group, "/aws/vpn/client/${local.name}")
  retention_in_days = var.client_vpn_log_retention_days

  tags = local.tags
}

resource "aws_cloudwatch_log_stream" "client_vpn" {
  count          = var.enable_client_vpn ? 1 : 0
  name           = "${local.name}-connections"
  log_group_name = aws_cloudwatch_log_group.client_vpn[0].name
}

# ---------------------------------------------------------------------------
# Client VPN Endpoint
# ---------------------------------------------------------------------------
resource "aws_ec2_client_vpn_endpoint" "this" {
  count = var.enable_client_vpn ? 1 : 0

  description            = "${local.name} Client VPN"
  server_certificate_arn = var.client_vpn_server_cert_arn
  client_cidr_block      = var.client_vpn_cidr
  split_tunnel           = var.client_vpn_split_tunnel
  transport_protocol     = var.client_vpn_transport_protocol
  vpn_port               = var.client_vpn_vpn_port
  session_timeout_hours  = var.client_vpn_session_timeout_hours
  vpc_id                 = var.client_vpn_vpc_id
  security_group_ids     = var.client_vpn_security_group_ids
  dns_servers            = var.client_vpn_dns_servers
  self_service_portal    = "enabled"

  # Authentication: mutual TLS
  dynamic "authentication_options" {
    for_each = var.client_vpn_root_cert_chain_arn != null ? [1] : []
    content {
      type                       = "certificate-authentication"
      root_certificate_chain_arn = var.client_vpn_root_cert_chain_arn
    }
  }

  # Authentication: federated (SAML/SSO)
  dynamic "authentication_options" {
    for_each = var.client_vpn_saml_provider_arn != null ? [1] : []
    content {
      type                           = "federated-authentication"
      saml_provider_arn              = var.client_vpn_saml_provider_arn
      self_service_saml_provider_arn = var.client_vpn_self_service_saml_provider_arn
    }
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.client_vpn[0].name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.client_vpn[0].name
  }

  tags = merge(local.tags, { Name = "${local.name}-client-vpn" })
}

# ---------------------------------------------------------------------------
# Network Associations (subnets)
# ---------------------------------------------------------------------------
resource "aws_ec2_client_vpn_network_association" "this" {
  for_each = var.enable_client_vpn ? toset(var.client_vpn_subnet_ids) : []

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  subnet_id              = each.value
}

# ---------------------------------------------------------------------------
# Authorization Rules
# ---------------------------------------------------------------------------
resource "aws_ec2_client_vpn_authorization_rule" "this" {
  for_each = var.enable_client_vpn ? var.client_vpn_authorization_rules : {}

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  target_network_cidr    = each.value.target_network_cidr
  access_group_id        = each.value.access_group_id
  authorize_all_groups   = each.value.authorize_all_groups
  description            = each.value.description
}

# ---------------------------------------------------------------------------
# Additional Routes
# ---------------------------------------------------------------------------
resource "aws_ec2_client_vpn_route" "this" {
  for_each = var.enable_client_vpn ? var.client_vpn_additional_routes : {}

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  destination_cidr_block = each.value.destination_cidr
  target_vpc_subnet_id   = each.value.target_vpc_subnet_id
  description            = each.value.description

  depends_on = [aws_ec2_client_vpn_network_association.this]
}
