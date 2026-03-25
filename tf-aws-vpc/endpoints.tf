# ---------------------------------------------------------------------------
# VPC Endpoints – Gateway (S3 / DynamoDB)
# ---------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_s3_endpoint ? 1 : 0
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [for rt in aws_route_table.private : rt.id],
    aws_route_table.public[*].id,
  )

  tags = merge(local.tags, { Name = "${local.name}-s3-endpoint" })
}

resource "aws_vpc_endpoint" "dynamodb" {
  count             = var.enable_dynamodb_endpoint ? 1 : 0
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [for rt in aws_route_table.private : rt.id]

  tags = merge(local.tags, { Name = "${local.name}-dynamodb-endpoint" })
}

# ---------------------------------------------------------------------------
# VPC Endpoints – Interface
# ---------------------------------------------------------------------------
resource "aws_vpc_endpoint" "interface" {
  for_each = var.interface_endpoints

  vpc_id              = aws_vpc.this.id
  service_name        = each.value.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = each.value.private_dns_enabled

  subnet_ids = length(each.value.subnet_ids) > 0 ? each.value.subnet_ids : [
    for s in aws_subnet.private : s.id
  ]

  security_group_ids = each.value.security_group_ids

  tags = merge(local.tags, { Name = "${local.name}-${each.key}-endpoint" })
}
