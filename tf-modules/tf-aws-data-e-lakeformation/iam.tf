locals {
  effective_role_arn = var.create_iam_role ? try(aws_iam_role.lakeformation[0].arn, null) : var.role_arn
}

data "aws_iam_policy_document" "lakeformation_assume_role" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid     = "LakeFormationAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lakeformation.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lakeformation" {
  count = var.create_iam_role ? 1 : 0

  name               = var.iam_role_name
  path               = var.iam_role_path
  assume_role_policy = data.aws_iam_policy_document.lakeformation_assume_role[0].json

  tags = merge(var.tags, var.iam_role_tags)
}

data "aws_iam_policy_document" "lakeformation_policy" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "LakeFormationDataAdmin"
    effect = "Allow"
    actions = [
      "lakeformation:*",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition",
      "glue:GetUserDefinedFunction",
      "glue:GetUserDefinedFunctions",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "S3DataLakeAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketAcl",
    ]
    resources = length(var.s3_bucket_arns) > 0 ? flatten([
      var.s3_bucket_arns,
      [for arn in var.s3_bucket_arns : "${arn}/*"],
    ]) : ["*"]
  }

  dynamic "statement" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      sid    = "KMSAccess"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey",
      ]
      resources = [var.kms_key_arn]
    }
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lakeformation/*",
    ]
  }
}

resource "aws_iam_policy" "lakeformation" {
  count = var.create_iam_role ? 1 : 0

  name   = "${var.iam_role_name}-policy"
  path   = var.iam_role_path
  policy = data.aws_iam_policy_document.lakeformation_policy[0].json

  tags = merge(var.tags, var.iam_role_tags)
}

resource "aws_iam_role_policy_attachment" "lakeformation" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.lakeformation[0].name
  policy_arn = aws_iam_policy.lakeformation[0].arn
}
