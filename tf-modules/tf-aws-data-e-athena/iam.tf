locals {
  # Build a flat list of workgroup ARNs from those declared in this module so
  # the analyst role can reference them.  Falls back to a wildcard when no
  # workgroups are defined.
  workgroup_arns_for_policy = length(var.workgroups) > 0 ? [
    for k in keys(var.workgroups) :
    "arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:workgroup/${k}"
  ] : ["arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:workgroup/*"]

  # Expand bucket ARNs to include the object-level prefix for S3 policies.
  results_bucket_object_arns = [
    for arn in var.results_bucket_arns : "${arn}/*"
  ]

  data_lake_bucket_object_arns = [
    for arn in var.data_lake_bucket_arns : "${arn}/*"
  ]
}

# ---------------------------------------------------------------------------
# Athena analyst IAM role
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "athena_analyst_assume" {
  statement {
    sid     = "AllowEC2AndLambdaAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "athena_analyst" {
  name               = "${var.name_prefix}-athena-analyst"
  assume_role_policy = data.aws_iam_policy_document.athena_analyst_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "athena_analyst" {
  statement {
    sid    = "AthenaQueryExecution"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetQueryResultsStream",
      "athena:StopQueryExecution",
      "athena:ListQueryExecutions",
      "athena:GetWorkGroup",
      "athena:ListWorkGroups",
      "athena:BatchGetQueryExecution",
    ]
    resources = local.workgroup_arns_for_policy
  }

  statement {
    sid    = "AthenaNamedQueryRead"
    effect = "Allow"
    actions = [
      "athena:GetNamedQuery",
      "athena:ListNamedQueries",
      "athena:CreateNamedQuery",
      "athena:DeleteNamedQuery",
    ]
    resources = local.workgroup_arns_for_policy
  }

  statement {
    sid    = "AthenaPreparedStatements"
    effect = "Allow"
    actions = [
      "athena:GetPreparedStatement",
      "athena:ListPreparedStatements",
      "athena:ExecutePreparedStatement",
    ]
    resources = local.workgroup_arns_for_policy
  }

  dynamic "statement" {
    for_each = length(var.results_bucket_arns) > 0 ? [1] : []
    content {
      sid    = "S3ResultsReadWrite"
      effect = "Allow"
      actions = [
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts",
      ]
      resources = concat(var.results_bucket_arns, local.results_bucket_object_arns)
    }
  }

  dynamic "statement" {
    for_each = length(var.data_lake_bucket_arns) > 0 ? [1] : []
    content {
      sid    = "S3DataLakeRead"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetBucketLocation",
      ]
      resources = concat(var.data_lake_bucket_arns, local.data_lake_bucket_object_arns)
    }
  }

  statement {
    sid    = "GlueCatalogRead"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition",
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*",
    ]
  }

  dynamic "statement" {
    for_each = var.results_kms_key_arn != null ? [var.results_kms_key_arn] : []
    content {
      sid    = "KMSResultsDecryptEncrypt"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey",
      ]
      resources = [statement.value]
    }
  }
}

resource "aws_iam_policy" "athena_analyst" {
  name        = "${var.name_prefix}-athena-analyst-policy"
  description = "Allows query execution and result retrieval in designated Athena workgroups."
  policy      = data.aws_iam_policy_document.athena_analyst.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "athena_analyst" {
  role       = aws_iam_role.athena_analyst.name
  policy_arn = aws_iam_policy.athena_analyst.arn
}

# ---------------------------------------------------------------------------
# Athena admin IAM role
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "athena_admin_assume" {
  statement {
    sid     = "AllowEC2AndLambdaAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "athena_admin" {
  name               = "${var.name_prefix}-athena-admin"
  assume_role_policy = data.aws_iam_policy_document.athena_admin_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "athena_admin" {
  statement {
    sid       = "AthenaFullAccess"
    effect    = "Allow"
    actions   = ["athena:*"]
    resources = ["*"]
  }

  statement {
    sid    = "GlueCatalogFullAccess"
    effect = "Allow"
    actions = [
      "glue:*Database*",
      "glue:*Table*",
      "glue:*Partition*",
      "glue:*Catalog*",
      "glue:GetConnection",
      "glue:GetConnections",
      "glue:GetDataCatalogEncryptionSettings",
      "glue:GetResourcePolicy",
      "glue:PutDataCatalogEncryptionSettings",
      "glue:PutResourcePolicy",
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*",
    ]
  }

  statement {
    sid    = "S3FullResultsAccess"
    effect = "Allow"
    actions = [
      "s3:*",
    ]
    resources = length(var.results_bucket_arns) > 0 ? concat(
      var.results_bucket_arns,
      local.results_bucket_object_arns,
    ) : ["*"]
  }

  statement {
    sid    = "S3DataLakeReadAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = length(var.data_lake_bucket_arns) > 0 ? concat(
      var.data_lake_bucket_arns,
      local.data_lake_bucket_object_arns,
    ) : ["*"]
  }

  dynamic "statement" {
    for_each = var.results_kms_key_arn != null ? [var.results_kms_key_arn] : []
    content {
      sid    = "KMSFullAccess"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey",
        "kms:CreateGrant",
        "kms:RetireGrant",
      ]
      resources = [statement.value]
    }
  }

  statement {
    sid    = "WorkgroupManagement"
    effect = "Allow"
    actions = [
      "athena:CreateWorkGroup",
      "athena:DeleteWorkGroup",
      "athena:UpdateWorkGroup",
      "athena:ListTagsForResource",
      "athena:TagResource",
      "athena:UntagResource",
    ]
    resources = ["arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:workgroup/*"]
  }

  statement {
    sid    = "CloudWatchMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["AmazonAthenaForApacheSpark", "AWS/Athena"]
    }
  }
}

resource "aws_iam_policy" "athena_admin" {
  name        = "${var.name_prefix}-athena-admin-policy"
  description = "Full Athena and Glue catalog administrative access."
  policy      = data.aws_iam_policy_document.athena_admin.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "athena_admin" {
  role       = aws_iam_role.athena_admin.name
  policy_arn = aws_iam_policy.athena_admin.arn
}

# ---------------------------------------------------------------------------
# Standalone policy documents for external attachment
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "s3_results" {
  dynamic "statement" {
    for_each = length(var.results_bucket_arns) > 0 ? [1] : []
    content {
      sid    = "S3AthenaResultsBucketAccess"
      effect = "Allow"
      actions = [
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts",
      ]
      resources = concat(var.results_bucket_arns, local.results_bucket_object_arns)
    }
  }
}
