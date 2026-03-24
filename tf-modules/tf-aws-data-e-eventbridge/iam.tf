# ── EventBridge invocation role ───────────────────────────────────────────────

data "aws_iam_policy_document" "eventbridge_assume_role" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid     = "EventBridgeAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eventbridge" {
  count = var.create_iam_role ? 1 : 0

  name               = var.iam_role_name
  path               = var.iam_role_path
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "eventbridge_policy" {
  count = var.create_iam_role ? 1 : 0

  dynamic "statement" {
    for_each = var.enable_lambda_target ? [1] : []
    content {
      sid       = "InvokeLambda"
      effect    = "Allow"
      actions   = ["lambda:InvokeFunction"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_sqs_target ? [1] : []
    content {
      sid       = "SQSSendMessage"
      effect    = "Allow"
      actions   = ["sqs:SendMessage"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_sns_target ? [1] : []
    content {
      sid       = "SNSPublish"
      effect    = "Allow"
      actions   = ["sns:Publish"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_kinesis_target ? [1] : []
    content {
      sid    = "KinesisPutRecord"
      effect = "Allow"
      actions = [
        "kinesis:PutRecord",
        "kinesis:PutRecords",
        "firehose:PutRecord",
        "firehose:PutRecordBatch",
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_stepfunctions_target ? [1] : []
    content {
      sid    = "StepFunctionsStartExecution"
      effect = "Allow"
      actions = [
        "states:StartExecution",
        "states:StartSyncExecution",
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_ecs_target ? [1] : []
    content {
      sid    = "ECSRunTask"
      effect = "Allow"
      actions = [
        "ecs:RunTask",
        "ecs:StopTask",
        "ecs:DescribeTasks",
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_ecs_target ? [1] : []
    content {
      sid       = "ECSPassRole"
      effect    = "Allow"
      actions   = ["iam:PassRole"]
      resources = ["*"]
      condition {
        test     = "StringLike"
        variable = "iam:PassedToService"
        values   = ["ecs-tasks.amazonaws.com"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.enable_batch_target ? [1] : []
    content {
      sid       = "BatchSubmitJob"
      effect    = "Allow"
      actions   = ["batch:SubmitJob"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_sagemaker_target ? [1] : []
    content {
      sid       = "SageMakerStartPipeline"
      effect    = "Allow"
      actions   = ["sagemaker:StartPipelineExecution"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_api_destination_target ? [1] : []
    content {
      sid       = "EventBridgeApiDestination"
      effect    = "Allow"
      actions   = ["events:InvokeApiDestination"]
      resources = ["arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:api-destination/*"]
    }
  }

  statement {
    sid    = "EventBridgePutEvents"
    effect = "Allow"
    actions = [
      "events:PutEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eventbridge" {
  count = var.create_iam_role ? 1 : 0

  name   = "${var.iam_role_name}-policy"
  path   = var.iam_role_path
  policy = data.aws_iam_policy_document.eventbridge_policy[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eventbridge" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.eventbridge[0].name
  policy_arn = aws_iam_policy.eventbridge[0].arn
}

# ── EventBridge Pipes execution role ─────────────────────────────────────────

data "aws_iam_policy_document" "eventbridge_pipes_assume_role" {
  count = var.create_iam_role && var.create_pipes ? 1 : 0

  statement {
    sid     = "EventBridgePipesAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["pipes.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eventbridge_pipes" {
  count = var.create_iam_role && var.create_pipes ? 1 : 0

  name               = var.pipes_role_name
  path               = var.iam_role_path
  assume_role_policy = data.aws_iam_policy_document.eventbridge_pipes_assume_role[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "eventbridge_pipes_policy" {
  count = var.create_iam_role && var.create_pipes ? 1 : 0

  statement {
    sid    = "PipesSourceAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:DescribeStream",
      "dynamodb:ListStreams",
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:DescribeStream",
      "kinesis:ListStreams",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "PipesTargetAccess"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "sqs:SendMessage",
      "sns:Publish",
      "kinesis:PutRecord",
      "kinesis:PutRecords",
      "states:StartExecution",
      "events:PutEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eventbridge_pipes" {
  count = var.create_iam_role && var.create_pipes ? 1 : 0

  name   = "${var.pipes_role_name}-policy"
  path   = var.iam_role_path
  policy = data.aws_iam_policy_document.eventbridge_pipes_policy[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eventbridge_pipes" {
  count = var.create_iam_role && var.create_pipes ? 1 : 0

  role       = aws_iam_role.eventbridge_pipes[0].name
  policy_arn = aws_iam_policy.eventbridge_pipes[0].arn
}
