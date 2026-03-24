data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# ---------------------------------------------------------------------------
# Cluster IAM Role
# ---------------------------------------------------------------------------
resource "aws_iam_role" "cluster" {
  count = var.cluster_role_arn == null ? 1 : 0

  name = "${local.name}-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy",
  ]

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Cluster Security Group
# ---------------------------------------------------------------------------
resource "aws_security_group" "cluster" {
  name        = "${local.name}-eks-cluster-sg"
  description = "EKS cluster control plane security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(local.tags, { Name = "${local.name}-eks-cluster-sg" })

  lifecycle { create_before_destroy = true }
}

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

# ---------------------------------------------------------------------------
# OIDC Provider (IRSA)
# ---------------------------------------------------------------------------
data "tls_certificate" "cluster" {
  count = var.enable_irsa ? 1 : 0
  url   = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Node Group IAM Role
# ---------------------------------------------------------------------------
resource "aws_iam_role" "node_group" {
  count = length(var.node_groups) > 0 ? 1 : 0

  name = "${local.name}-eks-node-group"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]

  tags = local.tags
}

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

# ---------------------------------------------------------------------------
# Fargate Profiles
# ---------------------------------------------------------------------------
resource "aws_iam_role" "fargate" {
  count = length(var.fargate_profiles) > 0 ? 1 : 0

  name = "${local.name}-eks-fargate"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks-fargate-pods.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy",
  ]

  tags = local.tags
}

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
