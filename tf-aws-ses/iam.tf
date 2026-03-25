# ── SES → Kinesis Firehose IAM Role ───────────────────────────────────────────
# Gated by create_iam_roles (top-level) or create_firehose_role (legacy).

locals {
  _create_firehose_role = var.create_iam_roles || var.create_firehose_role
  _create_s3_role       = var.create_iam_roles || var.create_s3_role
}

data "aws_iam_policy_document" "ses_firehose_assume" {
  count = local._create_firehose_role ? 1 : 0

  statement {
    sid     = "SESAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "ses_firehose" {
  count = local._create_firehose_role ? 1 : 0

  name               = var.firehose_role_name
  assume_role_policy = data.aws_iam_policy_document.ses_firehose_assume[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "ses_firehose_policy" {
  count = local._create_firehose_role ? 1 : 0

  statement {
    sid    = "FirehosePutRecord"
    effect = "Allow"
    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch",
    ]
    resources = ["arn:aws:firehose:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deliverystream/*"]
  }
}

resource "aws_iam_role_policy" "ses_firehose" {
  count = local._create_firehose_role ? 1 : 0

  name   = "ses-firehose-delivery-policy"
  role   = aws_iam_role.ses_firehose[0].id
  policy = data.aws_iam_policy_document.ses_firehose_policy[0].json
}

# ── SES → S3 Inbound Mail IAM Role ────────────────────────────────────────────

data "aws_iam_policy_document" "ses_s3_assume" {
  count = local._create_s3_role ? 1 : 0

  statement {
    sid     = "SESAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "ses_s3" {
  count = local._create_s3_role ? 1 : 0

  name               = var.s3_role_name
  assume_role_policy = data.aws_iam_policy_document.ses_s3_assume[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "ses_s3_policy" {
  count = local._create_s3_role ? 1 : 0

  statement {
    sid    = "S3PutInboundMail"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]
    resources = ["arn:aws:s3:::*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "KMSGenerateKey"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role_policy" "ses_s3" {
  count = local._create_s3_role ? 1 : 0

  name   = "ses-s3-inbound-policy"
  role   = aws_iam_role.ses_s3[0].id
  policy = data.aws_iam_policy_document.ses_s3_policy[0].json
}

# ── SES Sending IAM Policy Document (for application roles) ───────────────────

data "aws_iam_policy_document" "ses_sending" {
  statement {
    sid    = "SESSendEmail"
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
      "ses:SendTemplatedEmail",
      "ses:SendBulkTemplatedEmail",
    ]

    resources = length(var.sending_identity_arns) > 0 ? concat(
      var.sending_identity_arns,
      # Also include identities created by this module
      [for k, v in aws_sesv2_email_identity.domain : v.arn],
      [for k, v in aws_sesv2_email_identity.email : v.arn],
    ) : ["arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:identity/*"]
  }
}
