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
