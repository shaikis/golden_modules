# ---------------------------------------------------------------------------
# IAM Role for AWS Comprehend
# Conditionally created; skip when the caller passes an existing role ARN.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "comprehend_assume_role" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid     = "ComprehendAssumeRole"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["comprehend.amazonaws.com"]
    }

    # Restrict to the current account to prevent confused deputy attacks
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "comprehend" {
  count = var.create_iam_role ? 1 : 0

  name_prefix        = "${local.name_prefix}comprehend-"
  assume_role_policy = data.aws_iam_policy_document.comprehend_assume_role[0].json

  tags = local.tags
}

# AWS-managed policy granting access to Comprehend APIs
resource "aws_iam_role_policy_attachment" "comprehend_full_access" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.comprehend[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/ComprehendFullAccess"
}

# ---------------------------------------------------------------------------
# Inline policy: S3 access for training data + KMS access when keys are set
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "comprehend_inline" {
  count = var.create_iam_role ? 1 : 0

  # S3 read access — scoped to the buckets declared in document_classifiers
  # and entity_recognizers; falls back to a wildcard when no URIs are known
  # at plan time (e.g. purely dynamic values).
  dynamic "statement" {
    for_each = length(local.all_s3_buckets) > 0 ? [1] : []

    content {
      sid    = "S3TrainingDataRead"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket",
      ]
      resources = flatten([
        for bucket in local.all_s3_buckets : [
          "arn:${data.aws_partition.current.partition}:s3:::${bucket}",
          "arn:${data.aws_partition.current.partition}:s3:::${bucket}/*",
        ]
      ])
    }
  }

  # Fallback: broad S3 read when no explicit URIs are configured yet
  dynamic "statement" {
    for_each = length(local.all_s3_buckets) == 0 ? [1] : []

    content {
      sid    = "S3TrainingDataReadWildcard"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket",
      ]
      resources = ["*"]
    }
  }

  # S3 write access so Comprehend can store output / test results
  statement {
    sid    = "S3TrainingDataWrite"
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = ["*"]
  }

  # KMS access — only included when at least one key is referenced
  dynamic "statement" {
    for_each = local.kms_enabled ? [1] : []

    content {
      sid    = "KMSKeyAccess"
      effect = "Allow"
      actions = [
        "kms:CreateGrant",
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:ReEncryptFrom",
        "kms:ReEncryptTo",
      ]
      resources = local.all_kms_key_arns
    }
  }
}

resource "aws_iam_role_policy" "comprehend_inline" {
  count = var.create_iam_role ? 1 : 0

  name   = "${local.name_prefix}comprehend-inline"
  role   = aws_iam_role.comprehend[0].id
  policy = data.aws_iam_policy_document.comprehend_inline[0].json
}
