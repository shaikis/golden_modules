data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  assign_generated_ipv6_cidr_block = var.enable_ipv6

  tags = merge(local.tags, { Name = local.name })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

# ---------------------------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  count  = var.create_igw && length(var.public_subnet_cidrs) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${local.name}-igw" })

  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Public Subnets
# ---------------------------------------------------------------------------
resource "aws_subnet" "public" {
  for_each = { for i, cidr in var.public_subnet_cidrs : var.availability_zones[i] => cidr }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(local.public_subnet_tags, {
    Name = "${local.name}-public-${each.key}"
  })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

resource "aws_route_table" "public" {
  count  = length(var.public_subnet_cidrs) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${local.name}-public-rt" })
}

resource "aws_route" "public_internet" {
  count                  = length(var.public_subnet_cidrs) > 0 && var.create_igw ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

# ---------------------------------------------------------------------------
# Private Subnets
# ---------------------------------------------------------------------------
resource "aws_subnet" "private" {
  for_each = { for i, cidr in var.private_subnet_cidrs : var.availability_zones[i] => cidr }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(local.private_subnet_tags, {
    Name = "${local.name}-private-${each.key}"
  })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

# ---------------------------------------------------------------------------
# Database (isolated) Subnets
# ---------------------------------------------------------------------------
resource "aws_subnet" "database" {
  for_each = { for i, cidr in var.database_subnet_cidrs : var.availability_zones[i] => cidr }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(local.database_subnet_tags, {
    Name = "${local.name}-database-${each.key}"
  })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

resource "aws_db_subnet_group" "database" {
  count = length(var.database_subnet_cidrs) >= 2 ? 1 : 0

  name        = "${local.name}-db-subnet-group"
  description = "Database subnet group for ${local.name}"
  subnet_ids  = [for s in aws_subnet.database : s.id]

  tags = merge(local.tags, { Name = "${local.name}-db-subnet-group" })
}

# ---------------------------------------------------------------------------
# Elastic IPs for NAT Gateways
# ---------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = merge(local.tags, {
    Name = "${local.name}-nat-eip-${count.index}"
  })

  depends_on = [aws_internet_gateway.this]
}

# ---------------------------------------------------------------------------
# NAT Gateways
# ---------------------------------------------------------------------------
locals {
  # Pick which public subnet(s) host the NAT gateway(s)
  nat_subnet_ids = [
    for az in slice(var.availability_zones, 0, local.nat_gateway_count) :
    aws_subnet.public[az].id
  ]
}

resource "aws_nat_gateway" "this" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = local.nat_subnet_ids[count.index]

  tags = merge(local.tags, {
    Name = "${local.name}-nat-${var.availability_zones[count.index]}"
  })

  depends_on = [aws_internet_gateway.this]

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Private Route Tables (one per NAT GW or one shared)
# ---------------------------------------------------------------------------
resource "aws_route_table" "private" {
  for_each = { for az in var.availability_zones : az => az if length(var.private_subnet_cidrs) > 0 }

  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${local.name}-private-rt-${each.key}" })
}

resource "aws_route" "private_nat" {
  for_each = aws_route_table.private

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = (
    local.nat_gateway_count == 0 ? null
    : var.single_nat_gateway ? aws_nat_gateway.this[0].id
    : aws_nat_gateway.this[index(var.availability_zones, each.key)].id
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# Database subnets use private route tables (no outbound internet)
resource "aws_route_table" "database" {
  count  = length(var.database_subnet_cidrs) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${local.name}-database-rt" })
}

resource "aws_route_table_association" "database" {
  for_each = aws_subnet.database

  subnet_id      = each.value.id
  route_table_id = aws_route_table.database[0].id
}

# ---------------------------------------------------------------------------
# VPN Gateway
# ---------------------------------------------------------------------------
resource "aws_vpn_gateway" "this" {
  count           = var.enable_vpn_gateway ? 1 : 0
  vpc_id          = aws_vpc.this.id
  amazon_side_asn = var.vpn_gateway_amazon_side_asn

  tags = merge(local.tags, { Name = "${local.name}-vgw" })
}

# ---------------------------------------------------------------------------
# DHCP Options
# ---------------------------------------------------------------------------
resource "aws_vpc_dhcp_options" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  domain_name         = var.dhcp_options_domain_name
  domain_name_servers = var.dhcp_options_domain_name_servers
  ntp_servers         = var.dhcp_options_ntp_servers

  tags = merge(local.tags, { Name = "${local.name}-dhcp-opts" })
}

resource "aws_vpc_dhcp_options_association" "this" {
  count           = var.enable_dhcp_options ? 1 : 0
  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

# ---------------------------------------------------------------------------
# VPC Flow Logs – CloudWatch Logs
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "flow_log" {
  count = local.flow_log_to_cloudwatch ? 1 : 0

  name              = "/aws/vpc/flowlogs/${local.name}"
  retention_in_days = var.flow_log_retention_days
  kms_key_id        = var.flow_log_kms_key_id

  tags = merge(local.tags, { Name = "${local.name}-flow-log-lg" })
}

resource "aws_iam_role" "flow_log" {
  count = local.flow_log_to_cloudwatch ? 1 : 0
  name  = "${local.name}-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "flow_log" {
  count = local.flow_log_to_cloudwatch ? 1 : 0
  name  = "${local.name}-vpc-flow-log-policy"
  role  = aws_iam_role.flow_log[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = "${aws_cloudwatch_log_group.flow_log[0].arn}:*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_log ? 1 : 0

  vpc_id       = aws_vpc.this.id
  traffic_type = var.flow_log_traffic_type
  iam_role_arn = local.flow_log_to_cloudwatch ? aws_iam_role.flow_log[0].arn : null
  log_destination = (
    local.flow_log_to_cloudwatch ? aws_cloudwatch_log_group.flow_log[0].arn
    : var.flow_log_destination_arn
  )
  log_destination_type = var.flow_log_destination_type

  tags = merge(local.tags, { Name = "${local.name}-flow-log" })
}

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
