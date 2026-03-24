# ---------------------------------------------------------------------------
# Transit Gateway
# ---------------------------------------------------------------------------
resource "aws_ec2_transit_gateway" "this" {
  description                     = "${local.name} Transit Gateway"
  amazon_side_asn                 = var.amazon_side_asn
  auto_accept_shared_attachments  = var.auto_accept_shared_attachments
  default_route_table_association = var.default_route_table_association
  default_route_table_propagation = var.default_route_table_propagation
  dns_support                     = var.dns_support
  vpn_ecmp_support                = var.vpn_ecmp_support
  multicast_support               = var.multicast_support
  transit_gateway_cidr_blocks     = var.transit_gateway_cidr_blocks

  tags = merge(local.tags, { Name = local.name })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

# ---------------------------------------------------------------------------
# VPC Attachments
# ---------------------------------------------------------------------------
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = var.vpc_attachments

  transit_gateway_id                              = aws_ec2_transit_gateway.this.id
  vpc_id                                          = each.value.vpc_id
  subnet_ids                                      = each.value.subnet_ids
  dns_support                                     = each.value.dns_support
  ipv6_support                                    = each.value.ipv6_support
  appliance_mode_support                          = each.value.appliance_mode_support
  transit_gateway_default_route_table_association = each.value.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = each.value.transit_gateway_default_route_table_propagation

  tags = merge(local.tags, { Name = "${local.name}-${each.key}" })

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Custom Route Tables
# ---------------------------------------------------------------------------
resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each = var.tgw_route_tables

  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags               = merge(local.tags, each.value.tags, { Name = "${local.name}-rt-${each.key}" })
}

# Route table associations (custom)
resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = {
    for k, v in var.vpc_attachments : k => v
    if v.route_table_key != null
  }

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table_key].id
}

# Route table propagations (custom)
resource "aws_ec2_transit_gateway_route_table_propagation" "vpc" {
  for_each = {
    for k, v in var.vpc_attachments : k => v
    if v.route_table_key != null
  }

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table_key].id
}

# ---------------------------------------------------------------------------
# Static Routes
# ---------------------------------------------------------------------------
resource "aws_ec2_transit_gateway_route" "this" {
  for_each = var.tgw_routes

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table_key].id
  destination_cidr_block         = each.value.destination_cidr
  blackhole                      = each.value.blackhole

  transit_gateway_attachment_id = (
    each.value.blackhole ? null
    : lookup(
      { for k, v in aws_ec2_transit_gateway_vpc_attachment.this : k => v.id },
      each.value.attachment_key, null
    )
  )
}

# ---------------------------------------------------------------------------
# Direct Connect Gateway Association
# ---------------------------------------------------------------------------
resource "aws_dx_gateway_association" "this" {
  for_each = var.dx_gateway_attachments

  dx_gateway_id               = each.value.dx_gateway_id
  associated_gateway_id       = aws_ec2_transit_gateway.this.id
  dx_gateway_owner_account_id = each.value.dx_gateway_owner_account_id
  allowed_prefixes            = each.value.allowed_prefixes
}

# ---------------------------------------------------------------------------
# AWS RAM – Resource Share
# ---------------------------------------------------------------------------
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
