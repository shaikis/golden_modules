# ---------------------------------------------------------------------------
# DataSync Agents
# ---------------------------------------------------------------------------

resource "aws_datasync_agent" "this" {
  for_each = var.create_agents ? var.agents : {}

  name            = each.value.name != null ? each.value.name : each.key
  activation_key  = each.value.activation_key
  ip_address      = each.value.ip_address
  vpc_endpoint_id = each.value.vpc_endpoint_id

  subnet_arns         = each.value.subnet_arns
  security_group_arns = each.value.security_group_arns

  tags = merge(var.tags, each.value.tags, {
    Name = each.value.name != null ? each.value.name : each.key
  })
}
