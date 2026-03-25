# ---------------------------------------------------------------------------
# Subnet Group
# ---------------------------------------------------------------------------
resource "aws_elasticache_subnet_group" "this" {
  count = var.subnet_group_name == null && length(var.subnet_ids) > 0 ? 1 : 0

  name        = "${local.name}-sg"
  description = "ElastiCache subnet group for ${local.name}"
  subnet_ids  = var.subnet_ids

  tags = local.tags
}
