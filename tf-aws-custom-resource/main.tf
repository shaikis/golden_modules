locals {
  name_prefix  = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name
  lambda_arn   = var.lambda_arn != null ? var.lambda_arn : (var.create_lambda ? aws_lambda_function.handler[0].arn : null)
  create_role  = var.create_lambda && var.lambda_role_arn == null

  common_tags = merge(var.tags, {
    Name        = local.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
    Pattern     = "custom-resource"
  })
}

# ── CloudWatch Log Group for Lambda ────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "lambda" {
  count = var.create_lambda ? 1 : 0

  name              = "/aws/lambda/${local.name_prefix}-cr-handler"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.common_tags
}

# ── IAM Role for Lambda ─────────────────────────────────────────────────────────
resource "aws_iam_role" "lambda" {
  count = local.create_role ? 1 : 0

  name = "${local.name_prefix}-cr-handler-role"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda" {
  count = local.create_role ? 1 : 0

  name = "${local.name_prefix}-cr-handler-policy"
  role = aws_iam_role.lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ], var.additional_policy_statements)
  })
}

# ── Lambda Function ─────────────────────────────────────────────────────────────
# The handler code must be placed at:
#   <caller_module>/lambda_src/handler.py  (zipped as handler.zip)
# See the included base_handler.py template for the cfnresponse pattern.
resource "aws_lambda_function" "handler" {
  count = var.create_lambda ? 1 : 0

  function_name = "${local.name_prefix}-cr-handler"
  description   = "CloudFormation Custom Resource handler for ${var.resource_type}"
  role          = local.create_role ? aws_iam_role.lambda[0].arn : var.lambda_role_arn
  runtime       = var.runtime
  handler       = "handler.lambda_handler"
  timeout       = var.timeout
  memory_size   = var.memory_size

  filename         = "${path.root}/lambda_src/handler.zip"
  source_code_hash = filebase64sha256("${path.root}/lambda_src/handler.zip")

  kms_key_arn = var.kms_key_arn

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
  tags       = local.common_tags
}

# ── CloudFormation Stack — Custom Resource ──────────────────────────────────────
resource "aws_cloudformation_stack" "custom_resource" {
  name               = "${local.name_prefix}-cr"
  timeout_in_minutes = var.stack_timeout_minutes
  tags               = local.common_tags

  # NOTE: CloudFormation Custom Resource stacks cannot have on_failure = "DO_NOTHING"
  # if the stack is being created. ROLLBACK is correct for new stacks.
  on_failure = "ROLLBACK"

  template_body = jsonencode({
    AWSTemplateFormatVersion = "2010-09-09"
    Description = "Custom Resource wrapper for ${var.resource_type} — managed by Terraform"

    Resources = {
      CustomResource = {
        Type = "Custom::${var.resource_type}"
        Properties = merge(
          {
            ServiceToken    = local.lambda_arn
            ResourceVersion = var.trigger_on_change
          },
          var.properties
        )
      }
    }

    Outputs = merge(
      {
        ResourcePhysicalId = {
          Description = "Physical ID of the provisioned resource."
          Value       = { "Ref" = "CustomResource" }
        }
      },
      {
        for output_name, attr_name in var.output_attributes :
        output_name => {
          Description = "Custom resource output: ${attr_name}"
          Value       = { "Fn::GetAtt" = ["CustomResource", attr_name] }
        }
      }
    )
  })

  depends_on = [aws_lambda_function.handler]
}
