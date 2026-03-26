locals {
  name_prefix = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  common_tags = merge(var.tags, {
    Name        = local.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

resource "aws_cloudwatch_log_group" "build" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = "/aws/codebuild/${local.name_prefix}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_iam_role" "codebuild" {
  name = "${local.name_prefix}-codebuild-role"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codebuild_base" {
  name = "${local.name_prefix}-codebuild-base"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "CloudWatchLogs"
          Effect = "Allow"
          Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
          Resource = var.enable_cloudwatch_logs ? [
            aws_cloudwatch_log_group.build[0].arn,
            "${aws_cloudwatch_log_group.build[0].arn}:*"
          ] : ["arn:aws:logs:*:*:*"]
        },
        {
          Sid      = "ECRAuth"
          Effect   = "Allow"
          Action   = ["ecr:GetAuthorizationToken"]
          Resource = "*"
        },
        {
          Sid    = "ECRPushPull"
          Effect = "Allow"
          Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:PutImage"
          ]
          Resource = "*"
        },
        {
          Sid    = "S3Artifacts"
          Effect = "Allow"
          Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject", "s3:GetBucketAcl", "s3:GetBucketLocation"]
          Resource = "*"
        }
      ],
      var.vpc_id != null ? [{
        Sid    = "VPCAccess"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:CreateNetworkInterfacePermission"
        ]
        Resource = "*"
      }] : [],
      var.kms_key_arn != null ? [{
        Sid      = "KMSEncryption"
        Effect   = "Allow"
        Action   = ["kms:GenerateDataKey", "kms:Decrypt", "kms:DescribeKey"]
        Resource = [var.kms_key_arn]
      }] : [],
      var.additional_policy_statements
    )
  })
}

resource "aws_codebuild_project" "this" {
  name           = local.name_prefix
  description    = var.description
  build_timeout  = var.build_timeout
  queued_timeout = var.queued_timeout
  service_role   = aws_iam_role.codebuild.arn
  encryption_key = var.kms_key_arn
  tags           = local.common_tags

  source {
    type      = var.source_type
    location  = var.source_location != "" ? var.source_location : null
    buildspec = var.buildspec != "" ? var.buildspec : null

    dynamic "git_submodules_config" {
      for_each = contains(["GITHUB", "GITHUB_ENTERPRISE", "BITBUCKET", "CODECOMMIT"], var.source_type) ? [1] : []
      content {
        fetch_submodules = false
      }
    }
  }

  artifacts {
    type      = var.artifacts_type
    location  = var.artifacts_type == "S3" ? var.artifacts_bucket : null
    path      = var.artifacts_type == "S3" ? var.artifacts_path : null
    packaging = var.artifacts_type == "S3" ? "ZIP" : null
  }

  environment {
    compute_type                = var.compute_type
    image                       = var.image
    type                        = var.image_type
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = var.privileged_mode

    dynamic "environment_variable" {
      for_each = var.environment_variables
      content {
        name  = environment_variable.key
        value = environment_variable.value.value
        type  = environment_variable.value.type
      }
    }
  }

  cache {
    type     = var.cache_type
    location = var.cache_type == "S3" ? var.cache_bucket : null
    modes    = var.cache_type == "LOCAL" ? var.cache_modes : null
  }

  logs_config {
    cloudwatch_logs {
      status     = var.enable_cloudwatch_logs ? "ENABLED" : "DISABLED"
      group_name = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.build[0].name : null
    }

    s3_logs {
      status   = var.enable_s3_logs ? "ENABLED" : "DISABLED"
      location = var.enable_s3_logs ? "${var.s3_logs_bucket}/${var.s3_logs_prefix}" : null
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_id != null ? [1] : []
    content {
      vpc_id             = var.vpc_id
      subnets            = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }
}
