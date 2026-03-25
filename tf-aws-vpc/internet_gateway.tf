resource "aws_internet_gateway" "this" {
  count  = var.create_igw && length(var.public_subnet_cidrs) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${local.name}-igw" })

  lifecycle {
    prevent_destroy = true
  }
}
