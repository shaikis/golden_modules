resource "aws_eip" "this" {
  for_each = local.eip_instances

  instance = aws_instance.this[each.key].id
  domain   = "vpc"

  tags = merge(local.instance_tags[each.key], {
    Name = "${local.instance_names[each.key]}-eip"
  })

  depends_on = [aws_instance.this]
}
