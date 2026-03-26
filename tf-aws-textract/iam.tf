# ──────────────────────────────────────────────────────────────────────────────
# IAM Role — Application / Caller role (Lambda, EC2, etc.) for Textract API
# ──────────────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "textract_assume_role" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid     = "AllowLambdaAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = concat(
        ["lambda.amazonaws.com", "ec2.amazonaws.com"],
        var.trusted_principals
      )
    }
  }
}

resource "aws_iam_role" "textract" {
  count = var.create_iam_role ? 1 : 0

  name               = "${local.name_prefix}textract-caller-role"
  description        = "IAM role for applications calling Amazon Textract APIs"
  assume_role_policy = data.aws_iam_policy_document.textract_assume_role[0].json

  tags = local.tags
}

# ── Inline policy: Textract API + S3 + SNS + SQS + KMS ───────────────────────

data "aws_iam_policy_document" "textract_permissions" {
  count = var.create_iam_role ? 1 : 0

  # Full Textract API access
  statement {
    sid    = "TextractFullAccess"
    effect = "Allow"
    actions = [
      "textract:AnalyzeDocument",
      "textract:AnalyzeExpense",
      "textract:AnalyzeID",
      "textract:DetectDocumentText",
      "textract:GetDocumentAnalysis",
      "textract:GetDocumentTextDetection",
      "textract:GetExpenseAnalysis",
      "textract:GetLendingAnalysis",
      "textract:StartDocumentAnalysis",
      "textract:StartDocumentTextDetection",
      "textract:StartExpenseAnalysis",
      "textract:StartLendingAnalysis",
    ]
    resources = ["*"]
  }

  # S3 read access for input documents
  dynamic "statement" {
    for_each = length(var.s3_input_bucket_arns) > 0 ? [1] : []
    content {
      sid    = "S3ReadInputDocuments"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion",
      ]
      resources = [for arn in var.s3_input_bucket_arns : "${arn}/*"]
    }
  }

  # S3 write access for output results
  dynamic "statement" {
    for_each = length(var.s3_output_bucket_arns) > 0 ? [1] : []
    content {
      sid    = "S3WriteOutputResults"
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:PutObjectAcl",
      ]
      resources = [for arn in var.s3_output_bucket_arns : "${arn}/*"]
    }
  }

  # SNS publish access for job notifications
  dynamic "statement" {
    for_each = length(local.sns_topic_arns) > 0 ? [1] : []
    content {
      sid       = "SNSPublishTextractTopics"
      effect    = "Allow"
      actions   = ["sns:Publish"]
      resources = local.sns_topic_arns
    }
  }

  # SQS access for result queue processing
  dynamic "statement" {
    for_each = length(local.sqs_queue_arns) > 0 ? [1] : []
    content {
      sid    = "SQSTextractQueues"
      effect = "Allow"
      actions = [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ChangeMessageVisibility",
      ]
      resources = local.sqs_queue_arns
    }
  }

  # KMS access for encrypted SNS/SQS resources
  dynamic "statement" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      sid    = "KMSEncryptDecrypt"
      effect = "Allow"
      actions = [
        "kms:GenerateDataKey",
        "kms:Decrypt",
        "kms:DescribeKey",
      ]
      resources = [var.kms_key_arn]
    }
  }
}

resource "aws_iam_role_policy" "textract" {
  count = var.create_iam_role ? 1 : 0

  name   = "${local.name_prefix}textract-caller-policy"
  role   = aws_iam_role.textract[0].id
  policy = data.aws_iam_policy_document.textract_permissions[0].json
}

# ──────────────────────────────────────────────────────────────────────────────
# IAM Role — Textract service role to publish async job results to SNS
# ──────────────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "textract_service_assume_role" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid     = "AllowTextractServiceAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["textract.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "textract_service" {
  count = var.create_iam_role ? 1 : 0

  name               = "${local.name_prefix}textract-service-role"
  description        = "IAM role assumed by the Textract service to publish async job results to SNS"
  assume_role_policy = data.aws_iam_policy_document.textract_service_assume_role[0].json

  tags = local.tags
}

data "aws_iam_policy_document" "textract_service_permissions" {
  count = var.create_iam_role ? 1 : 0

  dynamic "statement" {
    for_each = length(local.sns_topic_arns) > 0 ? [1] : []
    content {
      sid       = "SNSPublishAsyncResults"
      effect    = "Allow"
      actions   = ["sns:Publish"]
      resources = local.sns_topic_arns
    }
  }

  # Fallback statement when no SNS topics exist yet (prevents empty policy)
  dynamic "statement" {
    for_each = length(local.sns_topic_arns) == 0 ? [1] : []
    content {
      sid       = "NoOpPlaceholder"
      effect    = "Deny"
      actions   = ["sns:Publish"]
      resources = ["arn:${data.aws_partition.current.partition}:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:placeholder-never-matches"]
    }
  }
}

resource "aws_iam_role_policy" "textract_service" {
  count = var.create_iam_role ? 1 : 0

  name   = "${local.name_prefix}textract-service-policy"
  role   = aws_iam_role.textract_service[0].id
  policy = data.aws_iam_policy_document.textract_service_permissions[0].json
}
