# ---------------------------------------------------------------------------
# IAM — SageMaker Execution Role
# ---------------------------------------------------------------------------

locals {
  sm_role_name = var.sagemaker_role_name != null ? var.sagemaker_role_name : "${var.name_prefix}sagemaker-execution-role"

  effective_role_arn = var.create_iam_role ? (
    length(aws_iam_role.sagemaker[*].arn) > 0 ? aws_iam_role.sagemaker[0].arn : null
  ) : var.role_arn

  s3_resources = flatten([
    for arn in var.data_bucket_arns : [arn, "${arn}/*"]
  ])

  has_s3_policy  = length(var.data_bucket_arns) > 0
  has_kms_policy = var.kms_key_arn != null
}

# ── Trust Policy ────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "sagemaker_assume_role" {
  statement {
    sid     = "SageMakerAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

# ── Service Role ─────────────────────────────────────────────────────────────

resource "aws_iam_role" "sagemaker" {
  count = var.create_iam_role ? 1 : 0

  name               = local.sm_role_name
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume_role.json
  description        = "SageMaker execution role managed by the tf-aws-data-e-sagemaker module."

  tags = merge(var.tags, { Name = local.sm_role_name })
}

# ── AWS Managed Policy ───────────────────────────────────────────────────────

resource "aws_iam_role_policy_attachment" "sagemaker_full" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.sagemaker[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# ── ECR Read Access ──────────────────────────────────────────────────────────

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  count = var.create_iam_role && var.enable_ecr_access ? 1 : 0

  role       = aws_iam_role.sagemaker[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ── Additional Managed Policies ───────────────────────────────────────────────

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = var.create_iam_role ? toset(var.additional_policy_arns) : toset([])

  role       = aws_iam_role.sagemaker[0].name
  policy_arn = each.value
}

# ── Inline Policy Document ────────────────────────────────────────────────────

data "aws_iam_policy_document" "sagemaker_inline" {
  # S3 — data / model bucket access
  dynamic "statement" {
    for_each = local.has_s3_policy ? [1] : []
    content {
      sid    = "DataBucketS3Access"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts",
      ]
      resources = local.s3_resources
    }
  }

  # KMS — encrypt / decrypt
  dynamic "statement" {
    for_each = local.has_kms_policy ? [1] : []
    content {
      sid    = "KMSAccess"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey",
        "kms:ReEncryptFrom",
        "kms:ReEncryptTo",
        "kms:CreateGrant",
      ]
      resources = [var.kms_key_arn]
    }
  }

  # CloudWatch Logs
  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/sagemaker/*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/sagemaker/*:*",
    ]
  }

  # CloudWatch Metrics
  statement {
    sid    = "CloudWatchMetricsAccess"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricData",
      "cloudwatch:ListMetrics",
    ]
    resources = ["*"]
  }

  # Glue Catalog — Feature Store offline tables
  dynamic "statement" {
    for_each = var.enable_glue_access ? [1] : []
    content {
      sid    = "GlueCatalogAccess"
      effect = "Allow"
      actions = [
        "glue:GetDatabase",
        "glue:GetDatabases",
        "glue:CreateDatabase",
        "glue:GetTable",
        "glue:GetTables",
        "glue:CreateTable",
        "glue:UpdateTable",
        "glue:DeleteTable",
        "glue:GetPartition",
        "glue:GetPartitions",
        "glue:BatchCreatePartition",
      ]
      resources = ["*"]
    }
  }

  # VPC — network interface permissions for VPC-mode training/hosting
  statement {
    sid    = "VPCNetworkInterfaceAccess"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:DeleteNetworkInterface",
      "ec2:DeleteNetworkInterfacePermission",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeDhcpOptions",
    ]
    resources = ["*"]
  }
}

# ── Attach Inline Policy ─────────────────────────────────────────────────────

resource "aws_iam_role_policy" "sagemaker_inline" {
  count = var.create_iam_role ? 1 : 0

  name   = "${local.sm_role_name}-inline"
  role   = aws_iam_role.sagemaker[0].id
  policy = data.aws_iam_policy_document.sagemaker_inline.json
}
