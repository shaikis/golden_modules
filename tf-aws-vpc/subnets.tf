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
