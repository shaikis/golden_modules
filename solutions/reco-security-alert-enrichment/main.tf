# ── KMS Key ────────────────────────────────────────────────────────────────────
module "kms" {
  source = "../../tf-aws-kms"
  count  = var.enable_kms_encryption ? 1 : 0

  name_prefix = local.prefix
  tags        = local.tags

  keys = {
    "pipeline" = {
      description      = "KMS key for ${local.prefix} security alert enrichment pipeline"
      admin_principals = []
      user_principals  = []
    }
  }
}

# ── IAM Role for Lambda ─────────────────────────────────────────────────────────
module "lambda_role" {
  source = "../../tf-aws-iam-role"

  name        = "${local.prefix}-lambda-alert-enrichment"
  environment = var.environment
  description = "Lambda execution role for security alert enrichment pipeline"
  tags        = local.tags

  trusted_role_services = ["lambda.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policies = {
    "alert-enrichment-access" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "BedrockInvoke"
          Effect   = "Allow"
          Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
          Resource = "*"
        },
        {
          Sid    = "S3ReadInput"
          Effect = "Allow"
          Action = ["s3:GetObject"]
          Resource = [
            "arn:aws:s3:::${local.prefix}-alerts-input/*",
            "arn:aws:s3:::${local.prefix}-examples/*"
          ]
        },
        {
          Sid    = "S3WriteOutput"
          Effect = "Allow"
          Action = ["s3:PutObject"]
          Resource = ["arn:aws:s3:::${local.prefix}-alerts-output/*"]
        },
        {
          Sid    = "SQSConsume"
          Effect = "Allow"
          Action = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
          Resource = "*"
        },
        {
          Sid    = "SNSPublish"
          Effect = "Allow"
          Action = ["sns:Publish"]
          Resource = "*"
        },
        {
          Sid    = "CloudWatchLogs"
          Effect = "Allow"
          Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
          Resource = "arn:aws:logs:*:*:*"
        }
      ]
    })
  }
}

# ── S3 Input Bucket (raw security alerts) ──────────────────────────────────────
module "s3_input" {
  source = "../../tf-aws-s3"

  bucket_name        = "${local.prefix}-alerts-input"
  environment        = var.environment
  tags               = local.tags
  versioning_enabled = true
  kms_master_key_id  = local.kms_key_arn

  lifecycle_rules = [
    {
      id      = "expire-raw-alerts"
      enabled = true
      expiration = {
        days = 90
      }
      noncurrent_version_expiration = {
        noncurrent_days = 14
      }
    }
  ]
}

# ── S3 Output Bucket (enriched alert JSON + Bedrock invocation logs) ───────────
module "s3_output" {
  source = "../../tf-aws-s3"

  bucket_name        = "${local.prefix}-alerts-output"
  environment        = var.environment
  tags               = local.tags
  versioning_enabled = true
  kms_master_key_id  = local.kms_key_arn

  lifecycle_rules = [
    {
      id      = "archive-enriched-alerts"
      enabled = true
      expiration = {
        days = 365
      }
    }
  ]
}

# ── S3 Examples Bucket (few-shot examples for Claude prompting) ────────────────
module "s3_examples" {
  source = "../../tf-aws-s3"

  bucket_name        = "${local.prefix}-examples"
  environment        = var.environment
  tags               = local.tags
  versioning_enabled = true
  kms_master_key_id  = local.kms_key_arn
}

# ── SQS Queue (Alert Processing) ───────────────────────────────────────────────
module "sqs" {
  source = "../../tf-aws-sqs"

  name        = "${local.prefix}-alerts"
  environment = var.environment
  tags        = local.tags

  visibility_timeout_seconds = var.sqs_visibility_timeout
  kms_master_key_id          = local.kms_key_arn
  create_dlq                 = true
  maxReceiveCount            = var.sqs_max_receive_count
}

# ── SNS Topic — high-severity alert notifications + CloudWatch alarms ──────────
module "sns_alerts" {
  source = "../../tf-aws-sns"
  count  = var.alarm_email != null ? 1 : 0

  name        = "${local.prefix}-alerts"
  environment = var.environment
  tags        = local.tags

  subscriptions = {
    "email-soc" = {
      protocol = "email"
      endpoint = var.alarm_email
    }
  }
}

# ── Lambda Function ─────────────────────────────────────────────────────────────
module "lambda" {
  source = "../../tf-aws-lambda"

  function_name = "${local.prefix}-alert-enrichment"
  description   = "Enriches security alerts using Amazon Bedrock Claude with few-shot prompting and Tool Use"
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"
  timeout       = var.lambda_timeout_sec
  memory_size   = var.lambda_memory_mb
  environment   = var.environment
  tags          = local.tags

  create_role = false
  role_arn    = module.lambda_role.role_arn

  kms_key_arn = local.kms_key_arn

  environment_variables = {
    OUTPUT_BUCKET             = module.s3_output.bucket_id
    EXAMPLES_BUCKET           = module.s3_examples.bucket_id
    EXAMPLES_KEY              = "few-shot/examples.json"
    CLAUDE_MODEL_ID           = var.claude_model_id
    SNS_ALERT_TOPIC_ARN       = var.alarm_email != null ? module.sns_alerts[0].topic_arn : ""
    BEDROCK_GUARDRAIL_ID      = local.bedrock_guardrail_id
    BEDROCK_GUARDRAIL_VERSION = local.bedrock_guardrail_version
  }

  filename = "${path.module}/lambda_src/handler.zip"

  event_source_mappings = {
    "sqs-alerts" = {
      event_source_arn = module.sqs.queue_arn
      batch_size       = 1
      enabled          = true
    }
  }

  create_cloudwatch_alarms    = true
  create_cloudwatch_dashboard = true
  alarm_sns_topic_arn         = var.alarm_email != null ? module.sns_alerts[0].topic_arn : null
}

# ── Amazon Bedrock Infrastructure ──────────────────────────────────────────────
# Provisions:
#   1. Model Invocation Logging — every Claude prompt + completion saved to S3 + CloudWatch
#   2. Guardrails             — PII anonymisation + content-safety filters on every invocation
module "bedrock" {
  source = "../../tf-aws-bedrock"

  name        = local.prefix
  environment = var.environment
  tags        = local.tags

  # ── Model Invocation Logging ──────────────────────────────────────────────
  enable_model_invocation_logging = var.enable_bedrock_logging
  invocation_log_s3_bucket        = var.enable_bedrock_logging ? module.s3_output.bucket_id : null
  invocation_log_s3_prefix        = "bedrock-invocation-logs/"
  invocation_log_retention_days   = 90
  kms_key_arn                     = local.kms_key_arn

  # ── Guardrails ────────────────────────────────────────────────────────────
  # Applied server-side on EVERY invoke_model call via guardrailIdentifier param.
  # Anonymises PII that may appear in alert data; blocks harmful content.
  guardrails = var.enable_bedrock_guardrail ? {
    "security-alerts" = {
      description            = "Guardrail for ${local.prefix} alert enrichment — PII + content safety"
      blocked_input_message  = "This alert cannot be processed due to content policy restrictions."
      blocked_output_message = "Alert enrichment response blocked by content safety policy."
      kms_key_arn            = local.kms_key_arn

      content_policy_filters = [
        { type = "HATE",          input_strength = "HIGH",   output_strength = "HIGH"   },
        { type = "VIOLENCE",      input_strength = "MEDIUM", output_strength = "HIGH"   },
        { type = "MISCONDUCT",    input_strength = "MEDIUM", output_strength = "MEDIUM" },
        { type = "PROMPT_ATTACK", input_strength = "HIGH",   output_strength = "NONE"   },
      ]

      sensitive_information_policy_config = [
        { type = "EMAIL",                    action = "ANONYMIZE" },
        { type = "PHONE",                    action = "ANONYMIZE" },
        { type = "NAME",                     action = "ANONYMIZE" },
        { type = "SSN",                      action = "BLOCK"     },
        { type = "CREDIT_DEBIT_CARD_NUMBER", action = "BLOCK"     },
        { type = "AWS_ACCESS_KEY",           action = "BLOCK"     },
        { type = "AWS_SECRET_KEY",           action = "BLOCK"     },
      ]
    }
  } : {}
}

locals {
  bedrock_guardrail_id      = var.enable_bedrock_guardrail ? module.bedrock.guardrail_ids["security-alerts"] : ""
  bedrock_guardrail_version = var.enable_bedrock_guardrail ? "DRAFT" : ""
}

# ── S3 -> SQS Event Notification ───────────────────────────────────────────────
resource "aws_s3_bucket_notification" "input" {
  bucket = module.s3_input.bucket_id

  queue {
    id            = "notify-json"
    queue_arn     = module.sqs.queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".json"
  }

  depends_on = [aws_sqs_queue_policy.allow_s3]
}

# ── SQS Queue Policy — allow S3 to send messages ───────────────────────────────
resource "aws_sqs_queue_policy" "allow_s3" {
  queue_url = module.sqs.queue_url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3SendMessage"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = module.sqs.queue_arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = module.s3_input.bucket_arn
          }
        }
      }
    ]
  })
}
