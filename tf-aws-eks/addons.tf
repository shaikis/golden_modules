# ---------------------------------------------------------------------------
# Add-ons
# ---------------------------------------------------------------------------
resource "aws_eks_addon" "this" {
  for_each = var.cluster_addons

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = each.value.addon_version
  resolve_conflicts_on_create = each.value.resolve_conflicts_on_create
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update
  service_account_role_arn    = each.value.service_account_role_arn
  configuration_values        = each.value.configuration_values

  tags = merge(local.tags, { Addon = each.key })

  lifecycle {
    ignore_changes = [addon_version]
  }

  depends_on = [aws_eks_node_group.this]
}
