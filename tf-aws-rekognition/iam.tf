# ---------------------------------------------------------------------------
# IAM Role for Rekognition
# Controlled by: create_iam_role = true (default)
# BYO pattern  : create_iam_role = false, role_arn = "<existing ARN>"
# ---------------------------------------------------------------------------

# Trust policy – allows Rekognition service to assume this role.
data "aws_iam_policy_document" "rekognition_assume_role" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid     = "RekognitionAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["rekognition.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rekognition" {
  count = var.create_iam_role ? 1 : 0

  name               = "${local.name_prefix}rekognition-role"
  assume_role_policy = data.aws_iam_policy_document.rekognition_assume_role[0].json

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Inline policy: scoped Rekognition permissions
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "rekognition_permissions" {
  count = var.create_iam_role ? 1 : 0

  # Core Rekognition actions required for all features.
  statement {
    sid    = "RekognitionCore"
    effect = "Allow"
    actions = [
      "rekognition:CreateCollection",
      "rekognition:DeleteCollection",
      "rekognition:DescribeCollection",
      "rekognition:ListCollections",
      "rekognition:IndexFaces",
      "rekognition:SearchFaces",
      "rekognition:SearchFacesByImage",
      "rekognition:DetectFaces",
      "rekognition:DetectLabels",
      "rekognition:DetectModerationLabels",
      "rekognition:DetectText",
      "rekognition:RecognizeCelebrities",
      "rekognition:CreateStreamProcessor",
      "rekognition:DeleteStreamProcessor",
      "rekognition:DescribeStreamProcessor",
      "rekognition:ListStreamProcessors",
      "rekognition:StartStreamProcessor",
      "rekognition:StopStreamProcessor",
      "rekognition:CreateProject",
      "rekognition:DeleteProject",
      "rekognition:DescribeProjects",
      "rekognition:CreateProjectVersion",
      "rekognition:DeleteProjectVersion",
      "rekognition:DescribeProjectVersions",
      "rekognition:StartProjectVersion",
      "rekognition:StopProjectVersion",
      "rekognition:DetectCustomLabels",
    ]
    resources = ["*"]
  }

  # S3 read – Rekognition reads source images / videos from S3.
  statement {
    sid    = "S3ReadAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListBucket",
    ]
    resources = ["*"]
  }

  # Kinesis Video Streams – used by stream processors as input.
  statement {
    sid    = "KinesisVideoAccess"
    effect = "Allow"
    actions = [
      "kinesisvideo:GetDataEndpoint",
      "kinesisvideo:GetMedia",
      "kinesisvideo:GetMediaForFragmentList",
      "kinesisvideo:ListFragments",
      "kinesisvideo:DescribeStream",
    ]
    resources = ["*"]
  }

  # Kinesis Data Streams – stream processor output.
  statement {
    sid    = "KinesisDataStreamAccess"
    effect = "Allow"
    actions = [
      "kinesis:PutRecord",
      "kinesis:PutRecords",
      "kinesis:DescribeStream",
    ]
    resources = ["*"]
  }

  # CloudWatch Logs – Rekognition can publish detection logs.
  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/rekognition/*",
    ]
  }

  # SNS publish – notification channels on stream processors.
  statement {
    sid    = "SNSPublishAccess"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "rekognition_permissions" {
  count = var.create_iam_role ? 1 : 0

  name   = "${local.name_prefix}rekognition-permissions"
  role   = aws_iam_role.rekognition[0].id
  policy = data.aws_iam_policy_document.rekognition_permissions[0].json
}

# ---------------------------------------------------------------------------
# Optional: KMS decrypt / generate data key (BYO key from tf-aws-kms)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "rekognition_kms" {
  count = var.create_iam_role && var.kms_key_arn != null ? 1 : 0

  statement {
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

resource "aws_iam_role_policy" "rekognition_kms" {
  count = var.create_iam_role && var.kms_key_arn != null ? 1 : 0

  name   = "${local.name_prefix}rekognition-kms"
  role   = aws_iam_role.rekognition[0].id
  policy = data.aws_iam_policy_document.rekognition_kms[0].json
}
