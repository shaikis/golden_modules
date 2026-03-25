# ---------------------------------------------------------------------------
# Public Route Table
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Database Route Table
# ---------------------------------------------------------------------------
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
