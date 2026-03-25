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
# Fargate IAM Role
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
