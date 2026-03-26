data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# ── IAM policy documents ────────────────────────────────────────

data "aws_iam_policy_document" "polly_assume_role" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid     = "AllowLambdaAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }

  statement {
    sid     = "AllowEC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "polly_inline" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "PollyAccess"
    effect = "Allow"
    actions = [
      "polly:SynthesizeSpeech",
      "polly:GetLexicon",
      "polly:ListLexicons",
      "polly:PutLexicon",
      "polly:DeleteLexicon",
      "polly:DescribeVoices",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.enable_s3_output && var.s3_output_bucket_arn != null ? [1] : []

    content {
      sid    = "S3OutputWrite"
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:PutObjectAcl",
      ]
      resources = [
        var.s3_output_bucket_arn,
        "${var.s3_output_bucket_arn}/*",
      ]
    }
  }
}
