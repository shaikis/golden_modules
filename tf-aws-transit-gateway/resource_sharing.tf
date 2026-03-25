resource "aws_ram_resource_share" "this" {
  count = var.ram_share_enabled ? 1 : 0

  name                      = "${local.name}-tgw-share"
  allow_external_principals = var.ram_allow_external_principals
  tags                      = local.tags
}

resource "aws_ram_resource_association" "tgw" {
  count = var.ram_share_enabled ? 1 : 0

  resource_arn       = aws_ec2_transit_gateway.this.arn
  resource_share_arn = aws_ram_resource_share.this[0].arn
}

resource "aws_ram_principal_association" "this" {
  for_each = var.ram_share_enabled ? toset(var.ram_principals) : []

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.this[0].arn
}
