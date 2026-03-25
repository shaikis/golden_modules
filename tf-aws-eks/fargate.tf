# ---------------------------------------------------------------------------
# Fargate Profiles
# ---------------------------------------------------------------------------
resource "aws_eks_fargate_profile" "this" {
  for_each = var.fargate_profiles

  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = each.key
  pod_execution_role_arn = aws_iam_role.fargate[0].arn
  subnet_ids             = length(each.value.subnet_ids) > 0 ? each.value.subnet_ids : var.subnet_ids

  dynamic "selector" {
    for_each = each.value.selectors
    content {
      namespace = selector.value.namespace
      labels    = selector.value.labels
    }
  }

  tags = merge(local.tags, { FargateProfile = each.key })
}
