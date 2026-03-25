locals {
  # Build cluster ARNs list for IAM policies
  cluster_arns_for_iam = [for k, v in aws_msk_cluster.this : v.arn]

  # Produce a unique role name suffix from the account + region to avoid collisions
  iam_suffix = "${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
}

# ---------------------------------------------------------------------------
# Producer Role
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "producer_assume_role" {
  count = var.create_iam_role ? 1 : 0

  dynamic "statement" {
    for_each = length(var.iam_producer_assume_role_principals) > 0 ? [1] : []
    content {
      sid     = "AllowAssumeRole"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "AWS"
        identifiers = var.iam_producer_assume_role_principals
      }
    }
  }

  # Allow EC2 and ECS tasks to assume the role by default
  statement {
    sid     = "AllowEC2ECS"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "producer" {
  count = var.create_iam_role ? 1 : 0

  name               = "${var.iam_role_name_prefix}-producer-${local.iam_suffix}"
  assume_role_policy = data.aws_iam_policy_document.producer_assume_role[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "producer_policy" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "MSKProducerCluster"
    effect = "Allow"
    actions = [
      "kafka-cluster:Connect",
      "kafka-cluster:DescribeCluster",
    ]
    resources = length(local.cluster_arns_for_iam) > 0 ? local.cluster_arns_for_iam : ["arn:aws:kafka:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/*/*"]
  }

  statement {
    sid    = "MSKProducerTopic"
    effect = "Allow"
    actions = [
      "kafka-cluster:WriteData",
      "kafka-cluster:CreateTopic",
      "kafka-cluster:DescribeTopic",
    ]
    resources = var.producer_topic_arns == ["*"] ? [
      "arn:aws:kafka:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/*/*/*"
    ] : var.producer_topic_arns
  }
}

resource "aws_iam_role_policy" "producer" {
  count = var.create_iam_role ? 1 : 0

  name   = "${var.iam_role_name_prefix}-producer-policy"
  role   = aws_iam_role.producer[0].id
  policy = data.aws_iam_policy_document.producer_policy[0].json
}

# ---------------------------------------------------------------------------
# Consumer Role
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "consumer_assume_role" {
  count = var.create_iam_role ? 1 : 0

  dynamic "statement" {
    for_each = length(var.iam_consumer_assume_role_principals) > 0 ? [1] : []
    content {
      sid     = "AllowAssumeRole"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "AWS"
        identifiers = var.iam_consumer_assume_role_principals
      }
    }
  }

  statement {
    sid     = "AllowEC2ECS"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "consumer" {
  count = var.create_iam_role ? 1 : 0

  name               = "${var.iam_role_name_prefix}-consumer-${local.iam_suffix}"
  assume_role_policy = data.aws_iam_policy_document.consumer_assume_role[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "consumer_policy" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "MSKConsumerCluster"
    effect = "Allow"
    actions = [
      "kafka-cluster:Connect",
      "kafka-cluster:DescribeCluster",
    ]
    resources = length(local.cluster_arns_for_iam) > 0 ? local.cluster_arns_for_iam : ["arn:aws:kafka:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/*/*"]
  }

  statement {
    sid    = "MSKConsumerTopic"
    effect = "Allow"
    actions = [
      "kafka-cluster:ReadData",
      "kafka-cluster:DescribeTopic",
    ]
    resources = var.consumer_topic_arns == ["*"] ? [
      "arn:aws:kafka:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/*/*/*"
    ] : var.consumer_topic_arns
  }

  statement {
    sid    = "MSKConsumerGroup"
    effect = "Allow"
    actions = [
      "kafka-cluster:AlterGroup",
      "kafka-cluster:DescribeGroup",
    ]
    resources = var.consumer_group_arns == ["*"] ? [
      "arn:aws:kafka:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:group/*/*/*"
    ] : var.consumer_group_arns
  }
}

resource "aws_iam_role_policy" "consumer" {
  count = var.create_iam_role ? 1 : 0

  name   = "${var.iam_role_name_prefix}-consumer-policy"
  role   = aws_iam_role.consumer[0].id
  policy = data.aws_iam_policy_document.consumer_policy[0].json
}
