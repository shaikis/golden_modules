resource "aws_vpn_gateway" "this" {
  count           = var.enable_vpn_gateway ? 1 : 0
  vpc_id          = aws_vpc.this.id
  amazon_side_asn = var.vpn_gateway_amazon_side_asn

  tags = merge(local.tags, { Name = "${local.name}-vgw" })
}
