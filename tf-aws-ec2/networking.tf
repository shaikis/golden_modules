# ---------------------------------------------------------------------------
# Elastic IP
# ---------------------------------------------------------------------------
resource "aws_eip" "this" {
  count    = var.create_eip && !var.use_spot ? 1 : 0
  instance = aws_instance.this.id
  domain   = "vpc"

  tags = merge(local.tags, { Name = "${local.name}-eip" })

  depends_on = [aws_instance.this]
}
