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
# Direct Connect Gateway Association
# ---------------------------------------------------------------------------
resource "aws_dx_gateway_association" "this" {
  for_each = {
    for k, v in var.dx_gateway_attachments : k => v
    if v.dx_gateway_owner_account_id == null
  }

  dx_gateway_id               = each.value.dx_gateway_id
  associated_gateway_id       = aws_ec2_transit_gateway.this.id
  allowed_prefixes            = each.value.allowed_prefixes
}

resource "aws_dx_gateway_association_proposal" "this" {
  for_each = {
    for k, v in var.dx_gateway_attachments : k => v
    if v.dx_gateway_owner_account_id != null
  }

  dx_gateway_id                    = each.value.dx_gateway_id
  associated_gateway_id            = aws_ec2_transit_gateway.this.id
  dx_gateway_owner_account_id      = each.value.dx_gateway_owner_account_id
  allowed_prefixes                 = each.value.allowed_prefixes
}
