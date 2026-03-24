# ---------------------------------------------------------------------------
# IAM — DataSync S3 Access Role
# ---------------------------------------------------------------------------

locals {
  ds_role_name = var.datasync_role_name != null ? var.datasync_role_name : "${var.name_prefix}datasync-s3-access-role"

  effective_role_arn = var.create_iam_role ? (
    length(aws_iam_role.datasync[*].arn) > 0 ? aws_iam_role.datasync[0].arn : null
  ) : var.role_arn

  s3_resources = flatten([
    for arn in var.s3_bucket_arns_for_role : [arn, "${arn}/*"]
  ])

  has_s3_policy  = length(var.s3_bucket_arns_for_role) > 0
  has_kms_policy = var.kms_key_arn != null
}

# ── Trust Policy ─────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "datasync_assume_role" {
  statement {
    sid     = "DataSyncAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }
  }
}

# ── Service Role ──────────────────────────────────────────────────────────────

resource "aws_iam_role" "datasync" {
  count = var.create_iam_role ? 1 : 0

  name               = local.ds_role_name
  assume_role_policy = data.aws_iam_policy_document.datasync_assume_role.json
  description        = "DataSync S3 access role managed by the tf-aws-data-e-datasync module."

  tags = merge(var.tags, { Name = local.ds_role_name })
}

# ── Inline Policy Document ────────────────────────────────────────────────────

data "aws_iam_policy_document" "datasync_inline" {
  # S3 — read/write on configured buckets
  dynamic "statement" {
    for_each = local.has_s3_policy ? [1] : []
    content {
      sid    = "DataSyncS3Access"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts",
        "s3:GetBucketVersioning",
        "s3:ListBucketVersions",
      ]
      resources = local.s3_resources
    }
  }

  # S3 — allow listing all buckets (needed for DataSync agent discovery)
  statement {
    sid    = "DataSyncS3ListAll"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
    ]
    resources = ["*"]
  }

  # KMS — for encrypted S3 buckets
  dynamic "statement" {
    for_each = local.has_kms_policy ? [1] : []
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
}

# ── Attach Inline Policy ──────────────────────────────────────────────────────

resource "aws_iam_role_policy" "datasync_inline" {
  count = var.create_iam_role ? 1 : 0

  name   = "${local.ds_role_name}-inline"
  role   = aws_iam_role.datasync[0].id
  policy = data.aws_iam_policy_document.datasync_inline.json
}
