# ── KMS Key ────────────────────────────────────────────────────────────────────
# module output: key_arns (map of key_name => ARN)
# module input:  name_prefix, keys (map), tags
module "kms" {
  source = "../../tf-aws-kms"
  count  = var.enable_kms_encryption ? 1 : 0

  name_prefix = local.prefix
  tags        = local.tags

  keys = {
    "pipeline" = {
      description      = "KMS key for ${local.prefix} entity recognition pipeline"
      admin_principals = []
      user_principals  = []
    }
  }
}

locals {
  kms_key_arn = var.enable_kms_encryption ? module.kms[0].key_arns["pipeline"] : null
}

# ── IAM Role for Lambda ─────────────────────────────────────────────────────────
# module: tf-aws-iam-role
# module output: role_arn, role_name
# module input:  name, trusted_role_services, managed_policy_arns, inline_policies, tags
module "lambda_role" {
  source = "../../tf-aws-iam-role"

  name        = "${local.prefix}-lambda-entity-recognition"
  environment = var.environment
  description = "Lambda execution role for entity recognition pipeline"
  tags        = local.tags

  trusted_role_services = ["lambda.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policies = {
    "bedrock-comprehend-s3-sqs-access" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "BedrockInvoke"
          Effect   = "Allow"
          Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
          Resource = "*"
        },
        {
          Sid      = "ComprehendDetect"
          Effect   = "Allow"
          Action   = ["comprehend:DetectEntities", "comprehend:BatchDetectEntities"]
          Resource = "*"
        },
        {
          Sid    = "S3ReadWriteInputOutput"
          Effect = "Allow"
          Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          Resource = [
            "arn:aws:s3:::${local.prefix}-input/*",
            "arn:aws:s3:::${local.prefix}-output/*"
          ]
        },
        {
          Sid    = "SQSConsume"
          Effect = "Allow"
          Action = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
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

# ── S3 Input Bucket ─────────────────────────────────────────────────────────────
# module output: bucket_id, bucket_arn, bucket_name
# module input:  bucket_name, kms_master_key_id (not kms_key_arn), versioning_enabled, lifecycle_rules (list)
module "s3_input" {
  source = "../../tf-aws-s3"

  bucket_name       = "${local.prefix}-input"
  environment       = var.environment
  tags              = local.tags
  versioning_enabled = true
  kms_master_key_id = local.kms_key_arn

  lifecycle_rules = [
    {
      id      = "expire-processed"
      enabled = true
      expiration = {
        days = 30
      }
      noncurrent_version_expiration = {
        noncurrent_days = 7
      }
    }
  ]
}

# ── S3 Output Bucket ────────────────────────────────────────────────────────────
module "s3_output" {
  source = "../../tf-aws-s3"

  bucket_name       = "${local.prefix}-output"
  environment       = var.environment
  tags              = local.tags
  versioning_enabled = true
  kms_master_key_id = local.kms_key_arn

  lifecycle_rules = [
    {
      id      = "archive-results"
      enabled = true
      expiration = {
        days = 365
      }
    }
  ]
}

# ── SQS Queue (Document Processing) ────────────────────────────────────────────
# module output: queue_id, queue_arn, queue_url, queue_name, dlq_id, dlq_arn, dlq_url
# module input:  name, visibility_timeout_seconds, kms_master_key_id, create_dlq, maxReceiveCount
module "sqs" {
  source = "../../tf-aws-sqs"

  name        = "${local.prefix}-documents"
  environment = var.environment
  tags        = local.tags

  visibility_timeout_seconds = var.sqs_visibility_timeout
  kms_master_key_id          = local.kms_key_arn
  create_dlq                 = true
  maxReceiveCount            = var.sqs_max_receive_count
}

# ── SNS Topic for Alerts (optional) ────────────────────────────────────────────
# module output: topic_arn, topic_name, topic_id
# module input:  name, subscriptions (map), tags
module "sns_alerts" {
  source = "../../tf-aws-sns"
  count  = var.alarm_email != null ? 1 : 0

  name        = "${local.prefix}-alerts"
  environment = var.environment
  tags        = local.tags

  subscriptions = {
    "email-ops" = {
      protocol = "email"
      endpoint = var.alarm_email
    }
  }
}

# ── Lambda Function ─────────────────────────────────────────────────────────────
# module output: function_name, function_arn, role_arn, log_group_name
# module input:  function_name, role_arn, create_role=false, runtime, handler, timeout,
#                memory_size, environment_variables, kms_key_arn, event_source_mappings,
#                create_cloudwatch_alarms, alarm_sns_topic_arn
module "lambda" {
  source = "../../tf-aws-lambda"

  function_name = "${local.prefix}-entity-recognition"
  description   = "Entity recognition using Bedrock Claude Tool Use + Amazon Comprehend"
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"
  timeout       = var.lambda_timeout_sec
  memory_size   = var.lambda_memory_mb
  environment   = var.environment
  tags          = local.tags

  # BYO role — disable module role creation
  create_role = false
  role_arn    = module.lambda_role.role_arn

  kms_key_arn = local.kms_key_arn

  environment_variables = {
    OUTPUT_BUCKET             = module.s3_output.bucket_id
    CLAUDE_MODEL_ID           = var.claude_model_id
    COMPREHEND_LANGUAGE_CODE  = var.comprehend_language_code
    ENABLE_COMPREHEND         = tostring(var.enable_comprehend_comparison)
    # Bedrock guardrail — enforced on every invoke_model call.
    # Empty string = no guardrail (when enable_bedrock_guardrail = false).
    BEDROCK_GUARDRAIL_ID      = local.bedrock_guardrail_id
    BEDROCK_GUARDRAIL_VERSION = local.bedrock_guardrail_version
  }

  # Inline Python source — base64-encoded zip is generated by the module
  filename = "${path.module}/lambda_src/handler.zip"

  # SQS event source mapping
  event_source_mappings = {
    "sqs-documents" = {
      event_source_arn = module.sqs.queue_arn
      batch_size       = 1
      enabled          = true
    }
  }

  # CloudWatch alarms
  create_cloudwatch_alarms  = true
  create_cloudwatch_dashboard = true
  alarm_sns_topic_arn       = var.alarm_email != null ? module.sns_alerts[0].topic_arn : null
}

# ── Amazon Bedrock Infrastructure ─────────────────────────────────────────────
# This is the CORE of the pipeline. The tf-aws-bedrock module provisions:
#   1. Model Invocation Logging  — every Claude API call is captured to S3 + CloudWatch
#   2. Guardrails                — PII anonymisation + content safety on every request/response
#   3. (Optional) Bedrock Agent  — orchestrates entity extraction as an autonomous agent
#
# The guardrail_id is injected into Lambda via environment variable so every
# boto3 bedrock-runtime.invoke_model() call enforces the guardrail.
module "bedrock" {
  source = "../../tf-aws-bedrock"

  name        = local.prefix
  environment = var.environment
  tags        = local.tags

  # ── Model Invocation Logging ──────────────────────────────────────────────
  # Logs every Claude prompt + completion to S3 and CloudWatch for audit/compliance.
  enable_model_invocation_logging   = var.enable_bedrock_logging
  invocation_log_s3_bucket          = var.enable_bedrock_logging ? module.s3_output.bucket_id : null
  invocation_log_s3_prefix          = "bedrock-invocation-logs/"
  invocation_log_retention_days     = 90
  kms_key_arn                       = local.kms_key_arn

  # ── Guardrails ────────────────────────────────────────────────────────────
  # Guards every Claude invocation in the entity recognition pipeline:
  #   - Blocks hateful / violent content in both input documents and model output
  #   - Anonymises PII (email, phone) so it is never stored in entity results
  #   - Blocks SSNs, credit card numbers, and AWS credentials outright
  guardrails = var.enable_bedrock_guardrail ? {
    "entity-extraction" = {
      description            = "Guardrail for ${local.prefix} entity recognition — PII + content safety"
      blocked_input_message  = "This document cannot be processed due to content policy restrictions."
      blocked_output_message = "Entity extraction response blocked by content safety policy."
      kms_key_arn            = local.kms_key_arn

      content_policy_filters = [
        { type = "HATE",         input_strength = "HIGH",   output_strength = "HIGH"   },
        { type = "VIOLENCE",     input_strength = "MEDIUM", output_strength = "HIGH"   },
        { type = "MISCONDUCT",   input_strength = "MEDIUM", output_strength = "MEDIUM" },
        { type = "PROMPT_ATTACK", input_strength = "HIGH",  output_strength = "NONE"   },
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
  # Resolved guardrail ID — passed to Lambda so every invoke_model enforces the guardrail.
  # Empty string when guardrails are disabled so Lambda skips the guardrailIdentifier param.
  bedrock_guardrail_id      = var.enable_bedrock_guardrail ? module.bedrock.guardrail_ids["entity-extraction"] : ""
  bedrock_guardrail_version = var.enable_bedrock_guardrail ? "DRAFT" : ""
}

# ── S3 → SQS Event Notification ────────────────────────────────────────────────
# Configured via native aws_s3_bucket_notification so both .txt and .pdf
# filters can be declared without requiring the module to support multi-suffix.
resource "aws_s3_bucket_notification" "input" {
  bucket = module.s3_input.bucket_id

  queue {
    id            = "notify-txt"
    queue_arn     = module.sqs.queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".txt"
  }

  queue {
    id            = "notify-pdf"
    queue_arn     = module.sqs.queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".pdf"
  }

  depends_on = [aws_sqs_queue_policy.allow_s3]
}

# ── SQS Queue Policy — allow S3 to send messages ────────────────────────────────
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
