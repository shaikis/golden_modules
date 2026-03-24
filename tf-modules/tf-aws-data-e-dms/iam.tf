# DMS requires two specific IAM role names. These names are hard-coded by AWS.
# See: https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html

# ---------------------------------------------------------------------------
# dms-vpc-role — allows DMS to manage VPC resources (ENIs, security groups)
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "dms_assume_role" {
  count = var.create_iam_roles ? 1 : 0

  statement {
    sid     = "DMSAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["dms.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dms_vpc_role" {
  count = var.create_iam_roles ? 1 : 0

  # This name is required by DMS — do NOT change it.
  name               = "dms-vpc-role"
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role[0].json
  description        = "Allows DMS to manage VPC networking resources."

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "dms_vpc_role" {
  count = var.create_iam_roles ? 1 : 0

  role       = aws_iam_role.dms_vpc_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

# ---------------------------------------------------------------------------
# dms-cloudwatch-logs-role — allows DMS to publish task logs to CloudWatch
# ---------------------------------------------------------------------------

resource "aws_iam_role" "dms_cloudwatch_logs_role" {
  count = var.create_iam_roles ? 1 : 0

  # This name is required by DMS — do NOT change it.
  name               = "dms-cloudwatch-logs-role"
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role[0].json
  description        = "Allows DMS to publish replication task logs to CloudWatch Logs."

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "dms_cloudwatch_logs_role" {
  count = var.create_iam_roles ? 1 : 0

  role       = aws_iam_role.dms_cloudwatch_logs_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
}

# ---------------------------------------------------------------------------
# Optional: DMS S3 access role for S3 endpoints
# (attached to s3_settings.service_access_role_arn by the caller)
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "dms_s3_role_assume" {
  count = var.create_iam_roles ? 1 : 0

  statement {
    sid     = "DMSAssumeRoleS3"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["dms.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dms_s3_role" {
  count = var.create_iam_roles ? 1 : 0

  name               = "dms-s3-access-role-${data.aws_region.current.name}"
  assume_role_policy = data.aws_iam_policy_document.dms_s3_role_assume[0].json
  description        = "Allows DMS to read/write S3 objects for S3 endpoints."

  tags = var.tags
}

data "aws_iam_policy_document" "dms_s3_policy" {
  count = var.create_iam_roles ? 1 : 0

  statement {
    sid    = "DMSS3Access"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObjectTagging",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "dms_s3_role" {
  count = var.create_iam_roles ? 1 : 0

  name   = "dms-s3-access-policy"
  role   = aws_iam_role.dms_s3_role[0].id
  policy = data.aws_iam_policy_document.dms_s3_policy[0].json
}
