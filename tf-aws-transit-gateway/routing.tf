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
