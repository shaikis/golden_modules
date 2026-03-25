# ---------------------------------------------------------------------------
# CloudWatch Log Group for Cluster Logs
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "cluster" {
  count = length(var.cluster_log_types) > 0 ? 1 : 0

  name              = "/aws/eks/${local.name}/cluster"
  retention_in_days = var.cluster_log_retention_days
  kms_key_id        = var.cluster_log_kms_key_id

  tags = local.tags
}

# ---------------------------------------------------------------------------
# EKS Cluster
# ---------------------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  name     = local.name
  version  = var.kubernetes_version
  role_arn = var.cluster_role_arn != null ? var.cluster_role_arn : aws_iam_role.cluster[0].arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = concat([aws_security_group.cluster.id], var.cluster_security_group_ids)
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : null
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.service_ipv4_cidr
    ip_family         = var.ip_family
  }

  dynamic "encryption_config" {
    for_each = var.secrets_kms_key_arn != null ? [1] : []
    content {
      resources = ["secrets"]
      provider {
        key_arn = var.secrets_kms_key_arn
      }
    }
  }

  enabled_cluster_log_types = var.cluster_log_types

  tags = local.tags

  depends_on = [
    aws_cloudwatch_log_group.cluster,
  ]

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}
