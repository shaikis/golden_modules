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
