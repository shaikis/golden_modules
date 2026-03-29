data "archive_file" "controller" {
  type        = "zip"
  source_file = "${path.module}/lambda/dr_controller.py"
  output_path = "${path.module}/.terraform-build/dr_controller.zip"
}

resource "aws_dynamodb_table" "dr_state" {
  count = var.create_state_table ? 1 : 0

  name         = var.state_table_name != null ? var.state_table_name : "${local.name}-dr-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "workflow_key"

  attribute {
    name = "workflow_key"
    type = "S"
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name}-controller"
  retention_in_days = var.cloudwatch_log_retention_days
  tags              = local.tags
}

resource "aws_cloudwatch_log_group" "step_functions" {
  name              = "/aws/vendedlogs/states/${local.name}-dr-control"
  retention_in_days = var.cloudwatch_log_retention_days
  tags              = local.tags
}

resource "aws_iam_role" "controller" {
  name = "${local.name}-dr-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "controller" {
  name = "${local.name}-dr-controller"
  role = aws_iam_role.controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }],
      length(var.allowed_secret_arns) > 0 ? [{
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.allowed_secret_arns
      }] : [],
      var.dns != null ? [{
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/${var.dns.zone_id}"
        }, {
        Effect = "Allow"
        Action = [
          "route53:GetChange"
        ]
        Resource = "*"
      }] : [],
      local.state_table_name != null ? [{
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = "arn:aws:dynamodb:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/${local.state_table_name}"
      }] : [],
      var.notification_topic_arn != null ? [{
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.notification_topic_arn
      }] : []
    )
  })
}

resource "aws_lambda_function" "controller" {
  function_name    = "${local.name}-dr-controller"
  role             = aws_iam_role.controller.arn
  runtime          = "python3.12"
  handler          = "dr_controller.handler"
  filename         = data.archive_file.controller.output_path
  source_code_hash = data.archive_file.controller.output_base64sha256
  timeout          = var.lambda_timeout_seconds
  memory_size      = var.lambda_memory_size

  dynamic "vpc_config" {
    for_each = length(var.lambda_subnet_ids) > 0 && length(var.lambda_security_group_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.lambda_subnet_ids
      security_group_ids = var.lambda_security_group_ids
    }
  }

  environment {
    variables = local.lambda_env
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
  tags       = local.tags
}

resource "aws_iam_role" "step_functions" {
  name = "${local.name}-dr-sfn"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "step_functions" {
  name = "${local.name}-dr-sfn"
  role = aws_iam_role.step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.controller.arn,
          "${aws_lambda_function.controller.arn}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_sfn_state_machine" "dr_control" {
  name       = "${local.name}-dr-control"
  role_arn   = aws_iam_role.step_functions.arn
  definition = local.step_function_definition

  logging_configuration {
    include_execution_data = true
    level                  = "ALL"
    log_destination        = "${aws_cloudwatch_log_group.step_functions.arn}:*"
  }

  tags = local.tags
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
