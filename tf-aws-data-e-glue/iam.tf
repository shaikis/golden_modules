# ---------------------------------------------------------------------------
# IAM — Glue Service Role
# ---------------------------------------------------------------------------

locals {
  role_name = var.service_role_name != null ? var.service_role_name : "${var.name_prefix}glue-service-role"

  # Build S3 resource list from bucket ARNs (bucket + objects).
  s3_resources = flatten([
    for arn in var.data_lake_bucket_arns : [arn, "${arn}/*"]
  ])

  # Determine whether any inline policy content is needed.
  has_s3_policy  = length(var.data_lake_bucket_arns) > 0
  has_kms_policy = length(var.kms_key_arns) > 0
}

# ---- Trust policy --------------------------------------------------------

data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    sid     = "GlueAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

# ---- Service role --------------------------------------------------------

resource "aws_iam_role" "glue_service" {
  count = var.create_iam_role ? 1 : 0

  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
  description        = "Glue service role managed by the tf-aws-glue module."

  tags = merge(var.tags, { Name = local.role_name })
}

# ---- AWS Managed policy --------------------------------------------------

resource "aws_iam_role_policy_attachment" "glue_managed" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.glue_service[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# ---- Additional managed policies ----------------------------------------

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = var.create_iam_role ? toset(var.additional_policy_arns) : toset([])

  role       = aws_iam_role.glue_service[0].name
  policy_arn = each.value
}

# ---- Inline policy document ---------------------------------------------

data "aws_iam_policy_document" "glue_inline" {
  # S3 — data lake read/write
  dynamic "statement" {
    for_each = local.has_s3_policy ? [1] : []
    content {
      sid    = "DataLakeS3Access"
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

  # KMS — decrypt / generate data key
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
      ]
      resources = var.kms_key_arns
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
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/*:*",
    ]
  }

  # Glue Catalog
  statement {
    sid    = "GlueCatalogAccess"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateDatabase",
      "glue:UpdateDatabase",
      "glue:GetTable",
      "glue:GetTables",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchCreatePartition",
      "glue:BatchDeletePartition",
      "glue:UpdatePartition",
      "glue:GetUserDefinedFunction",
      "glue:GetUserDefinedFunctions",
    ]
    resources = ["*"]
  }

  # Secrets Manager — JDBC passwords
  dynamic "statement" {
    for_each = var.enable_secrets_manager_access ? [1] : []
    content {
      sid    = "SecretsManagerRead"
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
      ]
      resources = [
        "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*",
      ]
    }
  }
}

# ---- Attach inline policy ------------------------------------------------

resource "aws_iam_role_policy" "glue_inline" {
  count = var.create_iam_role ? 1 : 0

  name   = "${local.role_name}-inline"
  role   = aws_iam_role.glue_service[0].id
  policy = data.aws_iam_policy_document.glue_inline.json
}
