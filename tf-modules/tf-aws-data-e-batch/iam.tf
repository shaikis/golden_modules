###############################################################################
# IAM – AWS Batch Service Role
###############################################################################

resource "aws_iam_role" "batch_service" {
  count = var.create_iam_role ? 1 : 0

  name = "batch-service-role-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BatchServiceTrust"
        Effect = "Allow"
        Principal = {
          Service = "batch.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "batch_service_policy" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.batch_service[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

###############################################################################
# IAM – EC2 Instance Role (for EC2-based compute environments)
###############################################################################

resource "aws_iam_role" "batch_ec2_instance" {
  count = var.create_iam_role ? 1 : 0

  name = "batch-ec2-instance-role-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

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

resource "aws_iam_role_policy_attachment" "batch_ec2_container_service" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.batch_ec2_instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "batch_ec2" {
  count = var.create_iam_role ? 1 : 0

  name = "batch-ec2-profile-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  role = aws_iam_role.batch_ec2_instance[0].name

  tags = var.tags
}

###############################################################################
# IAM – ECS Task Execution Role (Fargate containers)
###############################################################################

resource "aws_iam_role" "ecs_task_execution" {
  count = var.create_iam_role ? 1 : 0

  name = "batch-ecs-task-execution-role-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECSTaskExecutionTrust"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.ecs_task_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

###############################################################################
# IAM – Job Role (container access to AWS services)
###############################################################################

resource "aws_iam_role" "batch_job" {
  count = var.create_iam_role ? 1 : 0

  name = "batch-job-role-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BatchJobTrust"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "batch_job_s3_dynamo" {
  count = var.create_iam_role ? 1 : 0

  name = "batch-job-s3-dynamo-access"
  role = aws_iam_role.batch_job[0].id

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
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      },
      {
        Sid    = "SSMParameterStore"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/*"
        ]
      }
    ]
  })
}

###############################################################################
# IAM – Spot Fleet Role
###############################################################################

resource "aws_iam_role" "spot_fleet" {
  count = var.create_iam_role ? 1 : 0

  name = "batch-spot-fleet-role-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SpotFleetTrust"
        Effect = "Allow"
        Principal = {
          Service = "spotfleet.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "spot_fleet_tagging" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.spot_fleet[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}
