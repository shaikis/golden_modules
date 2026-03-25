# ---------------------------------------------------------------------------
# Managed Node Groups
# ---------------------------------------------------------------------------
resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node_group[0].arn
  subnet_ids      = length(each.value.subnet_ids) > 0 ? each.value.subnet_ids : var.node_groups_default_subnet_ids

  ami_type       = each.value.ami_type
  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.launch_template_id == null ? each.value.disk_size : null

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  update_config {
    max_unavailable = each.value.max_unavailable
  }

  labels = each.value.labels

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  dynamic "launch_template" {
    for_each = each.value.launch_template_id != null ? [1] : []
    content {
      id      = each.value.launch_template_id
      version = each.value.launch_template_version
    }
  }

  tags = merge(local.tags, { NodeGroup = each.key })

  lifecycle {
    # Ignore desired_size changes (managed by Cluster Autoscaler)
    ignore_changes        = [scaling_config[0].desired_size, tags["CreatedDate"]]
    create_before_destroy = true
  }

  depends_on = [aws_iam_role.node_group]
}
