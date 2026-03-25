resource "aws_customer_gateway" "this" {
  for_each = var.enable_site_to_site_vpn ? var.customer_gateways : {}

  bgp_asn         = each.value.bgp_asn
  ip_address      = each.value.ip_address
  type            = each.value.type
  device_name     = each.value.device_name
  certificate_arn = each.value.certificate_arn

  tags = merge(local.tags, { Name = "${local.name}-cgw-${each.key}" })
}
