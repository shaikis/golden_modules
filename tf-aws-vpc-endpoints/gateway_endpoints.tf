# ===========================================================================
# GATEWAY ENDPOINTS (S3, DynamoDB — no ENI, no cost)
# ===========================================================================
resource "aws_vpc_endpoint" "gateway" {
  for_each = local.gateway_endpoints

  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Gateway"
  service_name      = can(regex("^com\\.amazonaws\\.", each.value.service_name)) ? each.value.service_name : "com.amazonaws.${local.region}.${each.value.service_name}"
  route_table_ids   = length(each.value.route_table_ids) > 0 ? each.value.route_table_ids : var.default_route_table_ids
  policy            = each.value.policy

  tags = merge(local.tags, { Name = "${local.name}-ep-${each.key}" })
}
