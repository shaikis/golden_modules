# ── MWAA Execution IAM Role ───────────────────────────────────────────────────
# Gated by create_iam_role = true (default)

data "aws_iam_policy_document" "mwaa_trust" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid     = "MWAATrust"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "airflow.amazonaws.com",
        "airflow-env.amazonaws.com",
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "mwaa" {
  count = var.create_iam_role ? 1 : 0

  name               = "${var.name_prefix}mwaa-execution-role"
  assume_role_policy = data.aws_iam_policy_document.mwaa_trust[0].json
  tags               = var.tags
}

# ── S3 DAG Bucket ─────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "mwaa_s3" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "S3DagBucketReadWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:GetBucketVersioning",
      "s3:GetBucketPublicAccessBlock",
    ]
    resources = flatten([
      [for env in var.environments : env.source_bucket_arn],
      [for env in var.environments : "${env.source_bucket_arn}/*"],
    ])
  }
}

resource "aws_iam_role_policy" "mwaa_s3" {
  count = var.create_iam_role ? 1 : 0

  name   = "mwaa-s3-dag-bucket"
  role   = aws_iam_role.mwaa[0].id
  policy = data.aws_iam_policy_document.mwaa_s3[0].json
}

# ── CloudWatch Logs ───────────────────────────────────────────────────────────

data "aws_iam_policy_document" "mwaa_logs" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:GetLogRecord",
      "logs:GetLogGroupFields",
      "logs:GetQueryResults",
      "logs:DescribeLogGroups",
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:airflow-*"]
  }

  statement {
    sid    = "CloudWatchMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "mwaa_logs" {
  count = var.create_iam_role ? 1 : 0

  name   = "mwaa-cloudwatch-logs"
  role   = aws_iam_role.mwaa[0].id
  policy = data.aws_iam_policy_document.mwaa_logs[0].json
}

# ── SQS (MWAA uses SQS internally) ───────────────────────────────────────────

data "aws_iam_policy_document" "mwaa_sqs" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "SQSMWAAInternal"
    effect = "Allow"
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:SendMessage",
    ]
    resources = ["arn:aws:sqs:${data.aws_region.current.name}:*:airflow-celery-*"]
  }
}

resource "aws_iam_role_policy" "mwaa_sqs" {
  count = var.create_iam_role ? 1 : 0

  name   = "mwaa-sqs-internal"
  role   = aws_iam_role.mwaa[0].id
  policy = data.aws_iam_policy_document.mwaa_sqs[0].json
}

# ── KMS (CMK encryption) ──────────────────────────────────────────────────────

data "aws_iam_policy_document" "mwaa_kms" {
  count = var.create_iam_role && var.kms_key_arn != null ? 1 : 0

  statement {
    sid    = "KMSDecryptForMWAA"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
    ]
    resources = [var.kms_key_arn]
  }
}

resource "aws_iam_role_policy" "mwaa_kms" {
  count = var.create_iam_role && var.kms_key_arn != null ? 1 : 0

  name   = "mwaa-kms-cmk"
  role   = aws_iam_role.mwaa[0].id
  policy = data.aws_iam_policy_document.mwaa_kms[0].json
}

# ── Secrets Manager (connections/variables stored as secrets) ─────────────────

data "aws_iam_policy_document" "mwaa_secrets" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "SecretsManagerReadConnections"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:airflow/*",
    ]
  }
}

resource "aws_iam_role_policy" "mwaa_secrets" {
  count = var.create_iam_role ? 1 : 0

  name   = "mwaa-secrets-manager"
  role   = aws_iam_role.mwaa[0].id
  policy = data.aws_iam_policy_document.mwaa_secrets[0].json
}

# ── MWAA Environment Self-Reference ──────────────────────────────────────────

data "aws_iam_policy_document" "mwaa_env" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "MWAAEnvironmentPermissions"
    effect = "Allow"
    actions = [
      "airflow:PublishMetrics",
    ]
    resources = ["arn:aws:airflow:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:environment/*"]
  }
}

resource "aws_iam_role_policy" "mwaa_env" {
  count = var.create_iam_role ? 1 : 0

  name   = "mwaa-environment-permissions"
  role   = aws_iam_role.mwaa[0].id
  policy = data.aws_iam_policy_document.mwaa_env[0].json
}

# ── Glue ───────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "mwaa_glue" {
  count = var.create_iam_role && var.enable_glue_permissions ? 1 : 0

  statement {
    sid    = "GlueJobOrchestration"
    effect = "Allow"
    actions = [
      "glue:StartJobRun",
      "glue:GetJobRun",
      "glue:GetJobRuns",
      "glue:BatchStopJobRun",
      "glue:StartCrawler",
      "glue:GetCrawler",
      "glue:StopCrawler",
      "glue:GetCrawlerMetrics",
      "glue:StartTrigger",
      "glue:StopTrigger",
      "glue:GetTrigger",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "mwaa_glue" {
  count = var.create_iam_role && var.enable_glue_permissions ? 1 : 0

  name   = "mwaa-glue"
  role   = aws_iam_role.mwaa[0].id
  policy = data.aws_iam_policy_document.mwaa_glue[0].json
}

# ── EMR ────────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "mwaa_emr" {
  count = var.create_iam_role && var.enable_emr_permissions ? 1 : 0

  statement {
    sid    = "EMRClusterManagement"
    effect = "Allow"
    actions = [
      "elasticmapreduce:RunJobFlow",
      "elasticmapreduce:DescribeCluster",
      "elasticmapreduce:ListInstances",
      "elasticmapreduce:TerminateJobFlows",
      "elasticmapreduce:AddJobFlowSteps",
      "elasticmapreduce:DescribeStep",
      "elasticmapreduce:CancelSteps",
      "elasticmapreduce:ListSteps",
      "elasticmapreduce:AddTags",
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

resource "aws_iam_role_policy" "mwaa_emr" {
  count = var.create_iam_role && var.enable_emr_permissions ? 1 : 0

  name   = "mwaa-emr"
  role   = aws_iam_role.mwaa[0].id
  policy = data.aws_iam_policy_document.mwaa_emr[0].json
}

# ── Redshift ───────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "mwaa_redshift" {
  count = var.create_iam_role && var.enable_redshift_permissions ? 1 : 0

  statement {
    sid    = "RedshiftAccess"
    effect = "Allow"
    actions = [
      "redshift:DescribeClusters",
      "redshift:GetClusterCredentials",
      "redshift-data:ExecuteStatement",
      "redshift-data:DescribeStatement",
      "redshift-data:GetStatementResult",
      "redshift-data:ListDatabases",
      "redshift-data:ListSchemas",
      "redshift-data:ListTables",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "mwaa_redshift" {
  count = var.create_iam_role && var.enable_redshift_permissions ? 1 : 0

  name   = "mwaa-redshift"
  role   = aws_iam_role.mwaa[0].id
  policy = data.aws_iam_policy_document.mwaa_redshift[0].json
}

# ── SageMaker ─────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "mwaa_sagemaker" {
  count = var.create_iam_role && var.enable_sagemaker_permissions ? 1 : 0

  statement {
    sid    = "SageMakerOrchestration"
    effect = "Allow"
    actions = [
      "sagemaker:StartPipelineExecution",
      "sagemaker:DescribePipelineExecution",
      "sagemaker:StopPipelineExecution",
      "sagemaker:CreateTrainingJob",
      "sagemaker:DescribeTrainingJob",
      "sagemaker:StopTrainingJob",
      "sagemaker:CreateProcessingJob",
      "sagemaker:DescribeProcessingJob",
      "sagemaker:StopProcessingJob",
    ]
    resources = ["*"]
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

resource "aws_iam_role_policy" "mwaa_sagemaker" {
  count = var.create_iam_role && var.enable_sagemaker_permissions ? 1 : 0

  name   = "mwaa-sagemaker"
  role   = aws_iam_role.mwaa[0].id
  policy = data.aws_iam_policy_document.mwaa_sagemaker[0].json
}

# ── Batch ─────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "mwaa_batch" {
  count = var.create_iam_role && var.enable_batch_permissions ? 1 : 0

  statement {
    sid    = "BatchJobManagement"
    effect = "Allow"
    actions = [
      "batch:SubmitJob",
      "batch:DescribeJobs",
      "batch:TerminateJob",
      "batch:ListJobs",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "mwaa_batch" {
  count = var.create_iam_role && var.enable_batch_permissions ? 1 : 0

  name   = "mwaa-batch"
  role   = aws_iam_role.mwaa[0].id
  policy = data.aws_iam_policy_document.mwaa_batch[0].json
}

# ── Lambda ─────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "mwaa_lambda" {
  count = var.create_iam_role && var.enable_lambda_permissions ? 1 : 0

  statement {
    sid    = "LambdaInvokeFromDAGs"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "lambda:InvokeAsync",
    ]
    resources = ["arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"]
  }
}

resource "aws_iam_role_policy" "mwaa_lambda" {
  count = var.create_iam_role && var.enable_lambda_permissions ? 1 : 0

  name   = "mwaa-lambda"
  role   = aws_iam_role.mwaa[0].id
  policy = data.aws_iam_policy_document.mwaa_lambda[0].json
}

# ── Step Functions ─────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "mwaa_sfn" {
  count = var.create_iam_role && var.enable_sfn_permissions ? 1 : 0

  statement {
    sid    = "StepFunctionsFromDAGs"
    effect = "Allow"
    actions = [
      "states:StartExecution",
      "states:DescribeExecution",
      "states:StopExecution",
      "states:ListExecutions",
    ]
    resources = ["arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:*"]
  }
}

resource "aws_iam_role_policy" "mwaa_sfn" {
  count = var.create_iam_role && var.enable_sfn_permissions ? 1 : 0

  name   = "mwaa-stepfunctions"
  role   = aws_iam_role.mwaa[0].id
  policy = data.aws_iam_policy_document.mwaa_sfn[0].json
}

# ── Additional managed policies ───────────────────────────────────────────────

resource "aws_iam_role_policy_attachment" "mwaa_additional" {
  for_each = var.create_iam_role ? toset(var.additional_policy_arns) : toset([])

  role       = aws_iam_role.mwaa[0].name
  policy_arn = each.value
}
