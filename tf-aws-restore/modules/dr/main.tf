provider "aws" {
  region = var.region
}

################ IAM ################
resource "aws_iam_role" "lambda_role" {
  name = "${var.name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "backup:*",
        "rds:*",
        "ec2:*",
        "route53:*",
        "ssm:*",
        "logs:*"
      ],
      Resource = "*"
    }]
  })
}

################ LAMBDAS ################
locals {
  functions = [
    "restore",
    "status",
    "validate",
    "cleanup",
    "cutover_rds",
    "cutover_ec2",
    "mount_ssm",
    "rollback_rds",
    "rollback_ec2"
  ]
}

resource "aws_lambda_function" "fn" {
  for_each = toset(local.functions)

  function_name = "${var.name}-${each.key}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"

  filename         = "${var.lambda_path}/${each.key}.zip"
  source_code_hash = filebase64sha256("${var.lambda_path}/${each.key}.zip")

  timeout = 60
}

################ STEP FUNCTION ROLE ################
resource "aws_iam_role" "sfn_role" {
  name = "${var.name}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "states.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "sfn_policy" {
  role = aws_iam_role.sfn_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "lambda:InvokeFunction",
      Resource = "*"
    }]
  })
}

################ STEP FUNCTION ################
resource "aws_sfn_state_machine" "dr" {
  name     = "${var.name}-dr"
  role_arn = aws_iam_role.sfn_role.arn

  definition = templatefile("${path.module}/step_function.asl.json", {
    restore_lambda_arn      = aws_lambda_function.fn["restore"].arn
    status_lambda_arn       = aws_lambda_function.fn["status"].arn
    validate_lambda_arn     = aws_lambda_function.fn["validate"].arn
    cleanup_lambda_arn      = aws_lambda_function.fn["cleanup"].arn
    cutover_rds_lambda_arn  = aws_lambda_function.fn["cutover_rds"].arn
    cutover_ec2_lambda_arn  = aws_lambda_function.fn["cutover_ec2"].arn
    mount_ssm_lambda_arn    = aws_lambda_function.fn["mount_ssm"].arn
    rollback_rds_lambda_arn = aws_lambda_function.fn["rollback_rds"].arn
    rollback_ec2_lambda_arn = aws_lambda_function.fn["rollback_ec2"].arn
  })
}