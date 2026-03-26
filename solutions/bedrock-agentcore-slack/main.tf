# ── Data Sources ───────────────────────────────────────────────────────────────
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ── KMS Key ────────────────────────────────────────────────────────────────────
module "kms" {
  source = "../../tf-aws-kms"
  count  = var.enable_kms_encryption ? 1 : 0

  name_prefix = local.prefix
  tags        = local.tags

  keys = {
    "pipeline" = {
      description      = "KMS key for ${local.prefix} Slack agent pipeline"
      admin_principals = []
      user_principals  = []
    }
  }
}

# ── Secrets Manager — Slack credentials ────────────────────────────────────────
module "secret_slack" {
  source = "../../tf-aws-secretsmanager"

  name        = "${local.prefix}-slack-credentials"
  environment = var.environment
  tags        = local.tags
  description = "Slack Bot Token and Signing Secret for ${local.prefix}"
  kms_key_id  = local.kms_key_arn

  secret_string = jsonencode({
    bot_token      = var.slack_bot_token
    signing_secret = var.slack_signing_secret
  })
}

# ── ECR Repository — agent container image ─────────────────────────────────────
module "ecr" {
  source = "../../tf-aws-ecr"

  name        = local.prefix
  environment = var.environment
  tags        = local.tags
  kms_key_arn = local.kms_key_arn

  repositories = {
    "agent" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      force_delete         = false
    }
  }
}

# ── S3 Bucket — build artifacts and Bedrock invocation logs ────────────────────
module "s3_artifacts" {
  source = "../../tf-aws-s3"

  bucket_name        = "${local.prefix}-artifacts"
  environment        = var.environment
  tags               = local.tags
  versioning_enabled = false
  kms_master_key_id  = local.kms_key_arn

  lifecycle_rules = [
    {
      id      = "expire-artifacts"
      enabled = true
      expiration = { days = 30 }
    }
  ]
}

# ── CodeBuild — ARM64 agent container image build ──────────────────────────────
module "codebuild" {
  source = "../../tf-aws-codebuild"

  name        = "${local.prefix}-agent-build"
  description = "Builds ARM64 container image for the ${local.prefix} Bedrock agent"
  environment = var.environment
  tags        = local.tags

  compute_type    = "BUILD_GENERAL1_SMALL"
  image           = "aws/codebuild/amazonlinux-aarch64-standard:3.0"
  image_type      = "ARM_CONTAINER"
  privileged_mode = true

  source_type = "NO_SOURCE"
  buildspec = yamlencode({
    version = "0.2"
    phases = {
      pre_build = {
        commands = [
          "aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY"
        ]
      }
      build = {
        commands = [
          "docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .",
          "docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest"
        ]
      }
      post_build = {
        commands = [
          "docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG",
          "docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest"
        ]
      }
    }
  })

  artifacts_type   = "S3"
  artifacts_bucket = module.s3_artifacts.bucket_id
  artifacts_path   = "codebuild"
  kms_key_arn      = local.kms_key_arn

  environment_variables = {
    ECR_REGISTRY = {
      value = split("/", module.ecr.repository_urls["agent"])[0]
      type  = "PLAINTEXT"
    }
    ECR_REPOSITORY = {
      value = "agent"
      type  = "PLAINTEXT"
    }
    IMAGE_TAG = {
      value = var.agent_image_tag
      type  = "PLAINTEXT"
    }
  }
}

# ── IAM Role for Lambda ─────────────────────────────────────────────────────────
module "lambda_role" {
  source = "../../tf-aws-iam-role"

  name        = "${local.prefix}-lambda-slack"
  environment = var.environment
  description = "Lambda execution role for Slack-Bedrock agent pipeline"
  tags        = local.tags

  trusted_role_services = ["lambda.amazonaws.com"]
  managed_policy_arns   = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  inline_policies = {
    "slack-agent-access" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "SecretsManagerRead"
          Effect   = "Allow"
          Action   = ["secretsmanager:GetSecretValue"]
          Resource = [module.secret_slack.secret_arn]
        },
        {
          Sid      = "BedrockAgentRuntime"
          Effect   = "Allow"
          Action   = ["bedrock-agent-runtime:InvokeAgent", "bedrock-agent-runtime:InvokeInlineAgent", "bedrock:InvokeModel"]
          Resource = "*"
        },
        {
          Sid      = "SQSAccess"
          Effect   = "Allow"
          Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:SendMessage"]
          Resource = "*"
        },
        {
          Sid      = "LambdaInvoke"
          Effect   = "Allow"
          Action   = ["lambda:InvokeFunction"]
          Resource = "*"
        },
        {
          Sid      = "CloudWatchLogs"
          Effect   = "Allow"
          Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
          Resource = "arn:aws:logs:*:*:*"
        }
      ]
    })
  }
}

# ── SQS FIFO Queue ─────────────────────────────────────────────────────────────
module "sqs" {
  source = "../../tf-aws-sqs"

  name        = "${local.prefix}-slack-messages"
  environment = var.environment
  tags        = local.tags

  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = var.sqs_visibility_timeout
  kms_master_key_id           = local.kms_key_arn
  create_dlq                  = true
  maxReceiveCount             = var.sqs_max_receive_count
}

# ── SNS — alarm notifications ──────────────────────────────────────────────────
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

# ── Lambda 1: Verification ─────────────────────────────────────────────────────
module "lambda_verification" {
  source = "../../tf-aws-lambda"

  function_name = "${local.prefix}-slack-verification"
  description   = "Validates Slack webhook signatures and triggers async processing"
  runtime       = "python3.12"
  handler       = "verification_handler.lambda_handler"
  timeout       = 10
  memory_size   = 256
  environment   = var.environment
  tags          = local.tags

  create_role = false
  role_arn    = module.lambda_role.role_arn
  kms_key_arn = local.kms_key_arn

  environment_variables = {
    SLACK_SECRET_ARN              = module.secret_slack.secret_arn
    SQS_INTEGRATION_FUNCTION_NAME = "${local.prefix}-slack-sqs-integration"
  }

  filename                    = "${path.module}/lambda_src/verification.zip"
  create_cloudwatch_alarms    = true
  create_cloudwatch_dashboard = false
  alarm_sns_topic_arn         = var.alarm_email != null ? module.sns_alerts[0].topic_arn : null
}

# ── Lambda 2: SQS Integration ──────────────────────────────────────────────────
module "lambda_sqs_integration" {
  source = "../../tf-aws-lambda"

  function_name = "${local.prefix}-slack-sqs-integration"
  description   = "Filters bot messages, posts placeholder, enqueues to SQS FIFO"
  runtime       = "python3.12"
  handler       = "sqs_handler.lambda_handler"
  timeout       = 30
  memory_size   = 256
  environment   = var.environment
  tags          = local.tags

  create_role = false
  role_arn    = module.lambda_role.role_arn
  kms_key_arn = local.kms_key_arn

  environment_variables = {
    SLACK_SECRET_ARN = module.secret_slack.secret_arn
    SQS_QUEUE_URL    = module.sqs.queue_url
  }

  filename                    = "${path.module}/lambda_src/sqs_integration.zip"
  create_cloudwatch_alarms    = true
  create_cloudwatch_dashboard = false
  alarm_sns_topic_arn         = var.alarm_email != null ? module.sns_alerts[0].topic_arn : null
}

# ── Lambda 3: Agent Integration ────────────────────────────────────────────────
module "lambda_agent_integration" {
  source = "../../tf-aws-lambda"

  function_name = "${local.prefix}-slack-agent-integration"
  description   = "Invokes Bedrock Agent and posts response to Slack thread"
  runtime       = "python3.12"
  handler       = "agent_handler.lambda_handler"
  timeout       = var.lambda_timeout_sec
  memory_size   = var.lambda_memory_mb
  environment   = var.environment
  tags          = local.tags

  create_role = false
  role_arn    = module.lambda_role.role_arn
  kms_key_arn = local.kms_key_arn

  environment_variables = {
    SLACK_SECRET_ARN          = module.secret_slack.secret_arn
    BEDROCK_AGENT_ID          = aws_bedrock_agent_agent.slack_agent.agent_id
    BEDROCK_AGENT_ALIAS_ID    = aws_bedrock_agent_agent_alias.slack_agent.agent_alias_id
    BEDROCK_GUARDRAIL_ID      = local.bedrock_guardrail_id
    BEDROCK_GUARDRAIL_VERSION = local.bedrock_guardrail_version
  }

  filename = "${path.module}/lambda_src/agent_integration.zip"

  event_source_mappings = {
    "sqs-slack" = {
      event_source_arn = module.sqs.queue_arn
      batch_size       = 1
      enabled          = true
    }
  }

  create_cloudwatch_alarms    = true
  create_cloudwatch_dashboard = true
  alarm_sns_topic_arn         = var.alarm_email != null ? module.sns_alerts[0].topic_arn : null
}

# ── API Gateway (HTTP API v2) ──────────────────────────────────────────────────
module "api_gateway" {
  source = "../../tf-aws-apigateway"

  name        = "${local.prefix}-slack"
  description = "HTTP API for Slack webhook events"
  environment = var.environment
  tags        = local.tags

  stage_name         = "v1"
  auto_deploy        = true
  enable_access_logs = true
  log_retention_days = 14

  routes = {
    "POST /slack/events" = {
      lambda_invoke_arn    = module.lambda_verification.invoke_arn
      lambda_function_name = module.lambda_verification.function_name
      timeout_milliseconds = 9000
    }
    "GET /health" = {
      lambda_invoke_arn    = module.lambda_verification.invoke_arn
      lambda_function_name = module.lambda_verification.function_name
      timeout_milliseconds = 5000
    }
  }
}

# ── Bedrock Infrastructure (guardrails + logging) ──────────────────────────────
module "bedrock" {
  source = "../../tf-aws-bedrock"

  name        = local.prefix
  environment = var.environment
  tags        = local.tags

  enable_model_invocation_logging = var.enable_bedrock_logging
  invocation_log_s3_bucket        = var.enable_bedrock_logging ? module.s3_artifacts.bucket_id : null
  invocation_log_s3_prefix        = "bedrock-invocation-logs/"
  invocation_log_retention_days   = 90
  kms_key_arn                     = local.kms_key_arn

  guardrails = var.enable_bedrock_guardrail ? {
    "slack-agent" = {
      description            = "Guardrail for ${local.prefix} Slack agent"
      blocked_input_message  = "I cannot process this request due to content policy restrictions."
      blocked_output_message = "My response was blocked by content safety policy."
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
        { type = "SSN",                      action = "BLOCK"     },
        { type = "CREDIT_DEBIT_CARD_NUMBER", action = "BLOCK"     },
        { type = "AWS_ACCESS_KEY",           action = "BLOCK"     },
        { type = "AWS_SECRET_KEY",           action = "BLOCK"     },
      ]
    }
  } : {}
}

locals {
  bedrock_guardrail_id      = var.enable_bedrock_guardrail ? module.bedrock.guardrail_ids["slack-agent"] : ""
  bedrock_guardrail_version = var.enable_bedrock_guardrail ? "DRAFT" : ""
}

# ── Bedrock Agent IAM Role ─────────────────────────────────────────────────────
resource "aws_iam_role" "bedrock_agent" {
  name = "${local.prefix}-bedrock-agent-role"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "bedrock.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
      }
    }]
  })
}

resource "aws_iam_role_policy" "bedrock_agent" {
  name = "${local.prefix}-bedrock-agent-policy"
  role = aws_iam_role.bedrock_agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel"]
      Resource = "arn:aws:bedrock:*::foundation-model/*"
    }]
  })
}

# ── Bedrock Agent ──────────────────────────────────────────────────────────────
resource "aws_bedrock_agent_agent" "slack_agent" {
  agent_name              = "${local.prefix}-slack-agent"
  description             = "Bedrock Agent for Slack integration"
  agent_resource_role_arn = aws_iam_role.bedrock_agent.arn
  foundation_model        = var.claude_model_id
  instruction             = var.agent_instruction

  idle_session_ttl_in_seconds = 600
  tags                        = local.tags
}

resource "aws_bedrock_agent_agent_alias" "slack_agent" {
  agent_id         = aws_bedrock_agent_agent.slack_agent.agent_id
  agent_alias_name = "${local.prefix}-slack-live"
  description      = "Live alias for Slack integration"
  tags             = local.tags
}
