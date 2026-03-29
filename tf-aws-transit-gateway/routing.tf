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
    if try(v.association_route_table_key, v.route_table_key, null) != null
  }

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[try(each.value.association_route_table_key, each.value.route_table_key, null)].id
}

# Route table propagations (custom)
resource "aws_ec2_transit_gateway_route_table_propagation" "vpc" {
  for_each = merge([
    for attachment_key, attachment in var.vpc_attachments : {
      for route_table_key in (
        length(try(attachment.propagation_route_table_keys, [])) > 0
        ? attachment.propagation_route_table_keys
        : (
          try(attachment.route_table_key, null) != null
          ? [attachment.route_table_key]
          : []
        )
      ) :
      "${attachment_key}-${route_table_key}" => {
        attachment_key = attachment_key
        route_table_key = route_table_key
      }
    }
  ]...)

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.value.attachment_key].id
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
    : coalesce(
      each.value.transit_gateway_attachment_id,
      lookup(
        { for k, v in aws_ec2_transit_gateway_vpc_attachment.this : k => v.id },
        each.value.attachment_key,
        null
      )
    )
  )
}
