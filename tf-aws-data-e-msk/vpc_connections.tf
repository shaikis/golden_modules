resource "aws_msk_vpc_connection" "this" {
  for_each = var.create_vpc_connections ? var.vpc_connections : {}

  target_cluster_arn = each.value.target_cluster_arn != null ? each.value.target_cluster_arn : aws_msk_cluster.this[each.value.cluster_key].arn
  authentication     = each.value.authentication
  client_subnets     = each.value.client_subnets
  security_groups    = each.value.security_groups
  vpc_id             = each.value.vpc_id

  tags = merge(var.tags, each.value.tags)
}
