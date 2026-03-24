# ---------------------------------------------------------------------------
# Standalone customer-managed IAM policies
# ---------------------------------------------------------------------------

locals {
  policy_names = {
    for k, v in var.policies :
    k => coalesce(v.name, "${var.name_prefix}-${k}")
  }
}

resource "aws_iam_policy" "this" {
  for_each = var.policies

  name        = local.policy_names[each.key]
  description = each.value.description
  path        = each.value.path
  policy      = each.value.policy_json

  tags = merge(var.tags, each.value.tags, {
    Name      = local.policy_names[each.key]
    ManagedBy = "terraform"
  })
}

# ---------------------------------------------------------------------------
# Built-in reusable policy documents (data sources only — no resources)
# These are exposed as module outputs so callers can embed them in inline_policies.
# ---------------------------------------------------------------------------

# --- S3 Data Lake Read -------------------------------------------------------

data "aws_iam_policy_document" "data_lake_read" {
  statement {
    sid    = "DataLakeRead"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:ListBucket",
      "s3:ListBucketVersions",
    ]
    resources = length(var.data_lake_bucket_arns) > 0 ? flatten([
      var.data_lake_bucket_arns,
      [for arn in var.data_lake_bucket_arns : "${arn}/*"],
    ]) : ["arn:aws:s3:::PLACEHOLDER"]
  }
}

# --- S3 Data Lake Write -------------------------------------------------------

data "aws_iam_policy_document" "data_lake_write" {
  statement {
    sid    = "DataLakeWrite"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = length(var.data_lake_bucket_arns) > 0 ? flatten([
      var.data_lake_bucket_arns,
      [for arn in var.data_lake_bucket_arns : "${arn}/*"],
    ]) : ["arn:aws:s3:::PLACEHOLDER"]
  }
}

# --- KMS Decrypt / GenerateDataKey -------------------------------------------

data "aws_iam_policy_document" "kms_usage" {
  statement {
    sid    = "KMSUsage"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:DescribeKey",
    ]
    resources = length(var.kms_key_arns) > 0 ? var.kms_key_arns : [
      "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/PLACEHOLDER"
    ]
  }
}

# --- CloudWatch Logs ---------------------------------------------------------

data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*",
    ]
  }
}

# --- Secrets Manager Read ----------------------------------------------------

data "aws_iam_policy_document" "secrets_manager_read" {
  statement {
    sid    = "SecretsManagerRead"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = length(var.secret_arns) > 0 ? var.secret_arns : [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:PLACEHOLDER"
    ]
  }
}

# --- SSM Parameter Store Read ------------------------------------------------

data "aws_iam_policy_document" "ssm_parameter_read" {
  statement {
    sid    = "SSMParameterRead"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters",
    ]
    resources = length(var.ssm_parameter_paths) > 0 ? var.ssm_parameter_paths : [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/PLACEHOLDER"
    ]
  }
}
