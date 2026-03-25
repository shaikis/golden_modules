resource "aws_security_group" "this" {
  name        = local.name
  description = var.description
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = var.revoke_rules_on_delete

  tags = local.tags

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags["CreatedDate"]]
  }
}
