# ---------------------------------------------------------------------------
# Cluster Parameter Group
# ---------------------------------------------------------------------------
resource "aws_rds_cluster_parameter_group" "this" {
  count = var.create_cluster_parameter_group ? 1 : 0

  name        = "${local.name}-cpg"
  family      = var.cluster_parameter_group_family
  description = "Aurora cluster parameter group for ${local.name}"

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = local.tags

  lifecycle { create_before_destroy = true }
}
