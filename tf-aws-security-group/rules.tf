# Ingress rules — one resource per rule for fine-grained lifecycle control
resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = var.ingress_rules

  security_group_id = aws_security_group.this.id
  description       = each.value.description

  from_port   = each.value.protocol == "-1" ? null : each.value.from_port
  to_port     = each.value.protocol == "-1" ? null : each.value.to_port
  ip_protocol = each.value.protocol

  # Only one of these may be set per rule
  cidr_ipv4                    = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks[0] : null
  cidr_ipv6                    = length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks[0] : null
  referenced_security_group_id = length(each.value.source_sg_ids) > 0 ? each.value.source_sg_ids[0] : null

  tags = merge(local.tags, { Rule = each.key })

  lifecycle {
    create_before_destroy = true
  }
}

# Egress rules
resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = var.egress_rules

  security_group_id = aws_security_group.this.id
  description       = each.value.description

  from_port   = each.value.protocol == "-1" ? null : each.value.from_port
  to_port     = each.value.protocol == "-1" ? null : each.value.to_port
  ip_protocol = each.value.protocol

  cidr_ipv4                    = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks[0] : null
  cidr_ipv6                    = length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks[0] : null
  referenced_security_group_id = length(each.value.dest_sg_ids) > 0 ? each.value.dest_sg_ids[0] : null

  tags = merge(local.tags, { Rule = each.key })

  lifecycle {
    create_before_destroy = true
  }
}
