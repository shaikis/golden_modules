###############################################################################
# IAM – EMR Service Role
###############################################################################

resource "aws_iam_role" "emr_service" {
  count = var.create_iam_role ? 1 : 0

  name = "emr-service-role-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EMRServiceTrust"
        Effect = "Allow"
        Principal = {
          Service = "elasticmapreduce.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:elasticmapreduce:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "emr_service_policy" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.emr_service[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEMRServicePolicy_v2"
}

resource "aws_iam_role_policy" "emr_service_s3" {
  count = var.create_iam_role ? 1 : 0

  name = "emr-service-s3-access"
  role = aws_iam_role.emr_service[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetEncryptionConfiguration",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = ["*"]
      }
    ]
  })
}

###############################################################################
# IAM – EC2 Instance Profile Role
###############################################################################

resource "aws_iam_role" "emr_ec2" {
  count = var.create_iam_role ? 1 : 0

  name = "emr-ec2-role-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2Trust"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "emr_ec2_policy" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.emr_ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

resource "aws_iam_role_policy" "emr_ec2_glue" {
  count = var.create_iam_role ? 1 : 0

  name = "emr-ec2-glue-s3-access"
  role = aws_iam_role.emr_ec2[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GlueCatalogAccess"
        Effect = "Allow"
        Action = [
          "glue:*"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "S3FullAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:ReEncrypt*",
          "kms:DescribeKey"
        ]
        Resource = var.kms_key_arn != null ? [var.kms_key_arn] : ["*"]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "emr_ec2" {
  count = var.create_iam_role ? 1 : 0

  name = "emr-ec2-profile-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  role = aws_iam_role.emr_ec2[0].name

  tags = var.tags
}

###############################################################################
# IAM – Autoscaling Role
###############################################################################

resource "aws_iam_role" "emr_autoscaling" {
  count = var.create_iam_role ? 1 : 0

  name = "emr-autoscaling-role-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EMRAutoscalingTrust"
        Effect = "Allow"
        Principal = {
          Service = [
            "elasticmapreduce.amazonaws.com",
            "application-autoscaling.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "emr_autoscaling_policy" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.emr_autoscaling[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforAutoScalingRole"
}
