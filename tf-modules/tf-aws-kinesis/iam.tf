# ---------------------------------------------------------------------------
# IAM — Kinesis producer, consumer, Firehose, Analytics, Lambda transform
# ---------------------------------------------------------------------------

locals {
  all_stream_arns = [
    for k, v in aws_kinesis_stream.this : v.arn
  ]

  producer_stream_arns = concat(
    local.all_stream_arns,
    var.producer_additional_stream_arns,
  )

  consumer_stream_arns = concat(
    local.all_stream_arns,
    var.consumer_additional_stream_arns,
  )

  effective_producer_role_name         = coalesce(var.producer_role_name, "${var.name_prefix}kinesis-producer")
  effective_consumer_role_name         = coalesce(var.consumer_role_name, "${var.name_prefix}kinesis-consumer")
  effective_firehose_role_name         = coalesce(var.firehose_role_name, "${var.name_prefix}kinesis-firehose")
  effective_lambda_transform_role_name = coalesce(var.lambda_transform_role_name, "${var.name_prefix}kinesis-lambda-transform")
}

# ---------------------------------------------------------------------------
# Producer Role
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "producer_assume" {
  count = var.create_iam_roles && var.create_producer_role ? 1 : 0

  statement {
    sid     = "AllowEC2LambdaAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "producer" {
  count = var.create_iam_roles && var.create_producer_role ? 1 : 0

  name               = local.effective_producer_role_name
  assume_role_policy = data.aws_iam_policy_document.producer_assume[0].json

  tags = merge(var.tags, { Name = local.effective_producer_role_name, ManagedBy = "terraform" })
}

data "aws_iam_policy_document" "producer" {
  count = var.create_iam_roles && var.create_producer_role ? 1 : 0

  statement {
    sid    = "KinesisWrite"
    effect = "Allow"
    actions = [
      "kinesis:PutRecord",
      "kinesis:PutRecords",
      "kinesis:DescribeStream",
      "kinesis:DescribeStreamSummary",
      "kinesis:ListShards",
    ]
    resources = length(local.producer_stream_arns) > 0 ? local.producer_stream_arns : ["*"]
  }

  statement {
    sid    = "KMSEncrypt"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Encrypt",
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["kinesis.*.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "producer" {
  count = var.create_iam_roles && var.create_producer_role ? 1 : 0

  name   = "kinesis-producer-policy"
  role   = aws_iam_role.producer[0].id
  policy = data.aws_iam_policy_document.producer[0].json
}

# ---------------------------------------------------------------------------
# Consumer Role
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "consumer_assume" {
  count = var.create_iam_roles && var.create_consumer_role ? 1 : 0

  statement {
    sid     = "AllowEC2LambdaAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "consumer" {
  count = var.create_iam_roles && var.create_consumer_role ? 1 : 0

  name               = local.effective_consumer_role_name
  assume_role_policy = data.aws_iam_policy_document.consumer_assume[0].json

  tags = merge(var.tags, { Name = local.effective_consumer_role_name, ManagedBy = "terraform" })
}

data "aws_iam_policy_document" "consumer" {
  count = var.create_iam_roles && var.create_consumer_role ? 1 : 0

  statement {
    sid    = "KinesisRead"
    effect = "Allow"
    actions = [
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:DescribeStream",
      "kinesis:DescribeStreamSummary",
      "kinesis:ListShards",
      "kinesis:ListStreams",
      "kinesis:SubscribeToShard",
    ]
    resources = length(local.consumer_stream_arns) > 0 ? local.consumer_stream_arns : ["*"]
  }

  statement {
    sid    = "KMSDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["kinesis.*.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "consumer" {
  count = var.create_iam_roles && var.create_consumer_role ? 1 : 0

  name   = "kinesis-consumer-policy"
  role   = aws_iam_role.consumer[0].id
  policy = data.aws_iam_policy_document.consumer[0].json
}

# ---------------------------------------------------------------------------
# Firehose Role
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "firehose_assume" {
  count = var.create_iam_roles && var.create_firehose_role ? 1 : 0

  statement {
    sid     = "AllowFirehoseAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "firehose" {
  count = var.create_iam_roles && var.create_firehose_role ? 1 : 0

  name               = local.effective_firehose_role_name
  assume_role_policy = data.aws_iam_policy_document.firehose_assume[0].json

  tags = merge(var.tags, { Name = local.effective_firehose_role_name, ManagedBy = "terraform" })
}

data "aws_iam_policy_document" "firehose" {
  count = var.create_iam_roles && var.create_firehose_role ? 1 : 0

  # Kinesis source stream access
  statement {
    sid    = "KinesisSourceRead"
    effect = "Allow"
    actions = [
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:DescribeStream",
      "kinesis:DescribeStreamSummary",
      "kinesis:ListShards",
    ]
    resources = length(local.all_stream_arns) > 0 ? local.all_stream_arns : ["*"]
  }

  # S3 delivery
  statement {
    sid    = "S3Delivery"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]
    resources = ["*"]
  }

  # CloudWatch logging
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
    ]
    resources = ["*"]
  }

  # KMS
  statement {
    sid    = "KMSAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.*.amazonaws.com", "kinesis.*.amazonaws.com"]
    }
  }

  # Glue schema registry (for data format conversion)
  statement {
    sid    = "GlueSchemaRegistry"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetTableVersion",
      "glue:GetTableVersions",
    ]
    resources = ["*"]
  }

  # Lambda invoke (for transformation processors)
  statement {
    sid    = "LambdaInvoke"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "lambda:GetFunctionConfiguration",
    ]
    resources = ["*"]
  }

  # OpenSearch / Elasticsearch delivery
  statement {
    sid    = "OpenSearchDelivery"
    effect = "Allow"
    actions = [
      "es:ESHttpPost",
      "es:ESHttpPut",
      "es:DescribeElasticsearchDomain",
      "es:DescribeElasticsearchDomains",
      "es:DescribeElasticsearchDomainConfig",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "firehose" {
  count = var.create_iam_roles && var.create_firehose_role ? 1 : 0

  name   = "kinesis-firehose-policy"
  role   = aws_iam_role.firehose[0].id
  policy = data.aws_iam_policy_document.firehose[0].json
}

# ---------------------------------------------------------------------------
# Analytics Role (one per application that needs auto-created role)
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "analytics_assume" {
  statement {
    sid     = "AllowKinesisAnalyticsAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["kinesisanalytics.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "analytics" {
  for_each = local.analytics_auto_role

  name               = coalesce(var.analytics_role_name, "${var.name_prefix}kinesis-analytics-${each.key}")
  assume_role_policy = data.aws_iam_policy_document.analytics_assume.json

  tags = merge(var.tags, each.value.tags, {
    Name      = "${var.name_prefix}kinesis-analytics-${each.key}"
    ManagedBy = "terraform"
  })
}

data "aws_iam_policy_document" "analytics" {
  for_each = local.analytics_auto_role

  # Full Kinesis stream access for source streams
  statement {
    sid    = "KinesisFullAccess"
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards",
      "kinesis:PutRecord",
      "kinesis:PutRecords",
    ]
    resources = length(local.all_stream_arns) > 0 ? local.all_stream_arns : ["*"]
  }

  # S3 code artifact access
  statement {
    sid    = "S3CodeAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${each.value.code_s3_bucket}/${each.value.code_s3_key}",
    ]
  }

  # S3 bucket-level for listing
  statement {
    sid    = "S3BucketList"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${each.value.code_s3_bucket}",
    ]
  }

  # CloudWatch logging
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  # VPC access (ENI management)
  statement {
    sid    = "VPCAccess"
    effect = "Allow"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:DeleteNetworkInterface",
    ]
    resources = ["*"]
  }

  # KMS
  statement {
    sid    = "KMSAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["kinesis.*.amazonaws.com", "s3.*.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "analytics" {
  for_each = local.analytics_auto_role

  name   = "kinesis-analytics-policy"
  role   = aws_iam_role.analytics[each.key].id
  policy = data.aws_iam_policy_document.analytics[each.key].json
}

# ---------------------------------------------------------------------------
# Lambda Transformation Role (optional)
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "lambda_transform_assume" {
  count = var.create_iam_roles && var.create_lambda_transform_role ? 1 : 0

  statement {
    sid     = "AllowLambdaAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_transform" {
  count = var.create_iam_roles && var.create_lambda_transform_role ? 1 : 0

  name               = local.effective_lambda_transform_role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_transform_assume[0].json

  tags = merge(var.tags, {
    Name      = local.effective_lambda_transform_role_name
    ManagedBy = "terraform"
  })
}

data "aws_iam_policy_document" "lambda_transform" {
  count = var.create_iam_roles && var.create_lambda_transform_role ? 1 : 0

  statement {
    sid    = "KinesisAccess"
    effect = "Allow"
    actions = [
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:DescribeStream",
      "kinesis:ListShards",
      "kinesis:PutRecord",
      "kinesis:PutRecords",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "KMSAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_transform" {
  count = var.create_iam_roles && var.create_lambda_transform_role ? 1 : 0

  name   = "lambda-transform-policy"
  role   = aws_iam_role.lambda_transform[0].id
  policy = data.aws_iam_policy_document.lambda_transform[0].json
}
