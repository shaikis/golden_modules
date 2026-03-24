# ── Step Functions Execution IAM Role ─────────────────────────────────────────
# Gated by create_iam_role = true (default)

data "aws_iam_policy_document" "sfn_trust" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid     = "StepFunctionsTrust"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "sfn" {
  count = var.create_iam_role ? 1 : 0

  name               = "${var.name_prefix}sfn-execution-role"
  assume_role_policy = data.aws_iam_policy_document.sfn_trust[0].json
  tags               = var.tags
}

# ── CloudWatch Logs ───────────────────────────────────────────────────────────

data "aws_iam_policy_document" "sfn_cloudwatch_logs" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "CloudWatchLogsDelivery"
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutLogEvents",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "sfn_cloudwatch_logs" {
  count = var.create_iam_role ? 1 : 0

  name   = "sfn-cloudwatch-logs"
  role   = aws_iam_role.sfn[0].id
  policy = data.aws_iam_policy_document.sfn_cloudwatch_logs[0].json
}

# ── X-Ray Tracing ─────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "sfn_xray" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "XRayTracing"
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "sfn_xray" {
  count = var.create_iam_role ? 1 : 0

  name   = "sfn-xray"
  role   = aws_iam_role.sfn[0].id
  policy = data.aws_iam_policy_document.sfn_xray[0].json
}

# ── Lambda ─────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "sfn_lambda" {
  count = var.create_iam_role && var.enable_lambda_permissions ? 1 : 0

  statement {
    sid    = "LambdaInvoke"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "lambda:InvokeAsync",
    ]
    resources = length(var.lambda_function_arns) > 0 ? (
      flatten([var.lambda_function_arns, [for arn in var.lambda_function_arns : "${arn}:*"]])
      ) : (
      ["arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"]
    )
  }
}

resource "aws_iam_role_policy" "sfn_lambda" {
  count = var.create_iam_role && var.enable_lambda_permissions ? 1 : 0

  name   = "sfn-lambda"
  role   = aws_iam_role.sfn[0].id
  policy = data.aws_iam_policy_document.sfn_lambda[0].json
}

# ── Glue ───────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "sfn_glue" {
  count = var.create_iam_role && var.enable_glue_permissions ? 1 : 0

  statement {
    sid    = "GlueJobTrigger"
    effect = "Allow"
    actions = [
      "glue:StartJobRun",
      "glue:GetJobRun",
      "glue:GetJobRuns",
      "glue:BatchStopJobRun",
      "glue:StartCrawler",
      "glue:GetCrawler",
      "glue:StopCrawler",
    ]
    resources = length(var.glue_job_arns) > 0 ? var.glue_job_arns : ["*"]
  }
}

resource "aws_iam_role_policy" "sfn_glue" {
  count = var.create_iam_role && var.enable_glue_permissions ? 1 : 0

  name   = "sfn-glue"
  role   = aws_iam_role.sfn[0].id
  policy = data.aws_iam_policy_document.sfn_glue[0].json
}

# ── ECS ────────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "sfn_ecs" {
  count = var.create_iam_role && var.enable_ecs_permissions ? 1 : 0

  statement {
    sid    = "ECSTaskRun"
    effect = "Allow"
    actions = [
      "ecs:RunTask",
      "ecs:StopTask",
      "ecs:DescribeTasks",
    ]
    resources = length(var.ecs_cluster_arns) > 0 ? var.ecs_cluster_arns : ["*"]
  }

  statement {
    sid    = "ECSPassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "sfn_ecs" {
  count = var.create_iam_role && var.enable_ecs_permissions ? 1 : 0

  name   = "sfn-ecs"
  role   = aws_iam_role.sfn[0].id
  policy = data.aws_iam_policy_document.sfn_ecs[0].json
}

# ── Batch ─────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "sfn_batch" {
  count = var.create_iam_role && var.enable_batch_permissions ? 1 : 0

  statement {
    sid    = "BatchJobSubmit"
    effect = "Allow"
    actions = [
      "batch:SubmitJob",
      "batch:DescribeJobs",
      "batch:TerminateJob",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "sfn_batch" {
  count = var.create_iam_role && var.enable_batch_permissions ? 1 : 0

  name   = "sfn-batch"
  role   = aws_iam_role.sfn[0].id
  policy = data.aws_iam_policy_document.sfn_batch[0].json
}

# ── SageMaker ─────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "sfn_sagemaker" {
  count = var.create_iam_role && var.enable_sagemaker_permissions ? 1 : 0

  statement {
    sid    = "SageMakerPipeline"
    effect = "Allow"
    actions = [
      "sagemaker:StartPipelineExecution",
      "sagemaker:StopPipelineExecution",
      "sagemaker:DescribePipelineExecution",
      "sagemaker:CreateTrainingJob",
      "sagemaker:DescribeTrainingJob",
      "sagemaker:StopTrainingJob",
      "sagemaker:CreateModel",
      "sagemaker:CreateEndpointConfig",
      "sagemaker:CreateEndpoint",
      "sagemaker:UpdateEndpoint",
    ]
    resources = length(var.sagemaker_pipeline_arns) > 0 ? var.sagemaker_pipeline_arns : ["*"]
  }

  statement {
    sid    = "SageMakerPassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "sfn_sagemaker" {
  count = var.create_iam_role && var.enable_sagemaker_permissions ? 1 : 0

  name   = "sfn-sagemaker"
  role   = aws_iam_role.sfn[0].id
  policy = data.aws_iam_policy_document.sfn_sagemaker[0].json
}

# ── DynamoDB ───────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "sfn_dynamodb" {
  count = var.create_iam_role && var.enable_dynamodb_permissions ? 1 : 0

  statement {
    sid    = "DynamoDBReadWrite"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
    ]
    resources = length(var.dynamodb_table_arns) > 0 ? (
      flatten([var.dynamodb_table_arns, [for arn in var.dynamodb_table_arns : "${arn}/index/*"]])
      ) : (
      ["arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*"]
    )
  }
}

resource "aws_iam_role_policy" "sfn_dynamodb" {
  count = var.create_iam_role && var.enable_dynamodb_permissions ? 1 : 0

  name   = "sfn-dynamodb"
  role   = aws_iam_role.sfn[0].id
  policy = data.aws_iam_policy_document.sfn_dynamodb[0].json
}

# ── SNS ────────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "sfn_sns" {
  count = var.create_iam_role && var.enable_sns_permissions ? 1 : 0

  statement {
    sid    = "SNSPublish"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = length(var.sns_topic_arns) > 0 ? var.sns_topic_arns : (
      ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    )
  }
}

resource "aws_iam_role_policy" "sfn_sns" {
  count = var.create_iam_role && var.enable_sns_permissions ? 1 : 0

  name   = "sfn-sns"
  role   = aws_iam_role.sfn[0].id
  policy = data.aws_iam_policy_document.sfn_sns[0].json
}

# ── SQS ────────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "sfn_sqs" {
  count = var.create_iam_role && var.enable_sqs_permissions ? 1 : 0

  statement {
    sid    = "SQSSendMessage"
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
    ]
    resources = length(var.sqs_queue_arns) > 0 ? var.sqs_queue_arns : (
      ["arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    )
  }
}

resource "aws_iam_role_policy" "sfn_sqs" {
  count = var.create_iam_role && var.enable_sqs_permissions ? 1 : 0

  name   = "sfn-sqs"
  role   = aws_iam_role.sfn[0].id
  policy = data.aws_iam_policy_document.sfn_sqs[0].json
}

# ── EMR ────────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "sfn_emr" {
  count = var.create_iam_role && var.enable_emr_permissions ? 1 : 0

  statement {
    sid    = "EMRClusterOperations"
    effect = "Allow"
    actions = [
      "elasticmapreduce:RunJobFlow",
      "elasticmapreduce:DescribeCluster",
      "elasticmapreduce:TerminateJobFlows",
      "elasticmapreduce:AddJobFlowSteps",
      "elasticmapreduce:DescribeStep",
      "elasticmapreduce:CancelSteps",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EMRPassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["elasticmapreduce.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "sfn_emr" {
  count = var.create_iam_role && var.enable_emr_permissions ? 1 : 0

  name   = "sfn-emr"
  role   = aws_iam_role.sfn[0].id
  policy = data.aws_iam_policy_document.sfn_emr[0].json
}

# ── Step Functions sub-workflow invocation ────────────────────────────────────

data "aws_iam_policy_document" "sfn_nested" {
  count = var.create_iam_role && var.enable_sfn_permissions ? 1 : 0

  statement {
    sid    = "StepFunctionsNested"
    effect = "Allow"
    actions = [
      "states:StartExecution",
      "states:DescribeExecution",
      "states:StopExecution",
    ]
    resources = ["arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:*"]
  }

  statement {
    sid    = "StepFunctionsEvents"
    effect = "Allow"
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule",
    ]
    resources = ["arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForStepFunctionsExecutionRule"]
  }
}

resource "aws_iam_role_policy" "sfn_nested" {
  count = var.create_iam_role && var.enable_sfn_permissions ? 1 : 0

  name   = "sfn-nested-workflows"
  role   = aws_iam_role.sfn[0].id
  policy = data.aws_iam_policy_document.sfn_nested[0].json
}

# ── Additional managed policies ───────────────────────────────────────────────

resource "aws_iam_role_policy_attachment" "sfn_additional" {
  for_each = var.create_iam_role ? toset(var.additional_policy_arns) : toset([])

  role       = aws_iam_role.sfn[0].name
  policy_arn = each.value
}
