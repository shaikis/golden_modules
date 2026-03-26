# ---------------------------------------------------------------------------
# IAM Role — created only when create_iam_role = true (default)
# Supports BYO pattern: set create_iam_role = false and supply role_arn
# ---------------------------------------------------------------------------

locals {
  iam_role_name = "${local.name_prefix}transcribe-role"
}

data "aws_iam_policy_document" "transcribe_trust" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid     = "TranscribeTrust"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "transcribe.amazonaws.com",
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "transcribe" {
  count = var.create_iam_role ? 1 : 0

  name               = local.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.transcribe_trust[0].json

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Managed policy: Amazon Transcribe Full Access
# ---------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "transcribe_full_access" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.transcribe[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonTranscribeFullAccess"
}

# ---------------------------------------------------------------------------
# Inline policy: S3 read for training / vocabulary input data
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "s3_read" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "S3ReadInputData"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "s3_read" {
  count = var.create_iam_role ? 1 : 0

  name   = "transcribe-s3-read"
  role   = aws_iam_role.transcribe[0].id
  policy = data.aws_iam_policy_document.s3_read[0].json
}

# ---------------------------------------------------------------------------
# Inline policy: KMS access (conditional on kms_key_arn)
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "kms_access" {
  count = var.create_iam_role && var.kms_key_arn != null ? 1 : 0

  statement {
    sid    = "KMSDecryptEncrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = [var.kms_key_arn]
  }
}

resource "aws_iam_role_policy" "kms_access" {
  count = var.create_iam_role && var.kms_key_arn != null ? 1 : 0

  name   = "transcribe-kms-access"
  role   = aws_iam_role.transcribe[0].id
  policy = data.aws_iam_policy_document.kms_access[0].json
}
