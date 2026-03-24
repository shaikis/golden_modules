resource "aws_msk_scram_secret_association" "this" {
  for_each = var.create_scram_auth ? var.scram_associations : {}

  cluster_arn     = aws_msk_cluster.this[each.value.cluster_key].arn
  secret_arn_list = each.value.secret_arn_list
}
