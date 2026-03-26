# =============================================================================
# EKS Conversational Observability — main.tf
# AI-powered EKS troubleshooting assistant using RAG + Bedrock + OpenSearch
# Reference: https://aws.amazon.com/blogs/architecture/architecting-conversational-observability-for-cloud-applications/
# =============================================================================

# ---------------------------------------------------------------------------
# Data Sources
# ---------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# Section 1: KMS
# ---------------------------------------------------------------------------
module "kms" {
  count  = var.enable_kms ? 1 : 0
  source = "../../tf-aws-kms"

  name_prefix = local.prefix
  tags        = local.tags

  keys = {
    "observability" = {
      description             = "KMS key for ${local.prefix} observability pipeline"
      enable_key_rotation     = true
      rotation_period_in_days = 365
      deletion_window_in_days = 30
      service_principals = [
        "kinesis.amazonaws.com",
        "s3.amazonaws.com",
        "lambda.amazonaws.com",
        "logs.${var.aws_region}.amazonaws.com",
      ]
    }
  }
}

# ---------------------------------------------------------------------------
# Section 2: VPC
# ---------------------------------------------------------------------------
module "vpc" {
  source = "../../tf-aws-vpc"

  name        = local.prefix
  environment = var.environment
  tags        = local.tags

  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs

  enable_nat_gateway  = true
  single_nat_gateway  = var.environment != "prod"
  create_igw          = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_flow_log           = true
  flow_log_destination_type = "cloud-watch-logs"
  flow_log_retention_days   = var.log_retention_days
  flow_log_kms_key_id       = local.kms_key_arn

  enable_s3_endpoint = true

  # EKS requires specific subnet tags for load balancer auto-discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${local.prefix}-eks" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${local.prefix}-eks" = "shared"
  }
}

# ---------------------------------------------------------------------------
# Section 3: EKS
# ---------------------------------------------------------------------------
module "eks" {
  source = "../../tf-aws-eks"

  name        = "${local.prefix}-eks"
  environment = var.environment
  tags        = local.tags

  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids_list

  endpoint_private_access = true
  endpoint_public_access  = false

  secrets_kms_key_arn = local.kms_key_arn
  cluster_log_kms_key_id = local.kms_key_arn
  cluster_log_retention_days = var.log_retention_days

  cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  enable_irsa = true

  node_groups = {
    main = {
      instance_types  = var.node_instance_types
      desired_size    = var.node_desired_size
      min_size        = var.node_min_size
      max_size        = var.node_max_size
      capacity_type   = "ON_DEMAND"
      disk_size       = 100
      kms_key_arn     = local.kms_key_arn
      labels = {
        role = "application"
      }
    }
  }

  node_groups_default_subnet_ids = module.vpc.private_subnet_ids_list

  cluster_addons = {
    coredns            = {}
    kube-proxy         = {}
    vpc-cni            = {}
    aws-ebs-csi-driver = {}
  }
}

# Fluent Bit for log forwarding to Kinesis via CloudWatch Observability add-on
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name = module.eks.cluster_name
  addon_name   = "amazon-cloudwatch-observability"
  tags         = local.tags

  depends_on = [module.eks]
}

# ---------------------------------------------------------------------------
# Section 4: Kinesis Data Stream
# ---------------------------------------------------------------------------
module "kinesis" {
  source = "../../tf-aws-kinesis"

  name_prefix = local.prefix
  tags        = local.tags

  kinesis_streams = {
    "telemetry" = {
      shard_count      = var.kinesis_shard_count
      on_demand        = false
      retention_period = var.kinesis_retention_hours
      encryption_type  = var.enable_kms ? "KMS" : "NONE"
      kms_key_id       = var.enable_kms ? local.kms_key_arn : "alias/aws/kinesis"
      shard_level_metrics = [
        "IncomingBytes",
        "IncomingRecords",
        "OutgoingBytes",
        "OutgoingRecords",
        "WriteProvisionedThroughputExceeded",
        "ReadProvisionedThroughputExceeded",
        "IteratorAgeMilliseconds",
      ]
    }
  }

  create_producer_role = true
  create_consumer_role = true
  create_firehose_role = false

  create_alarms         = true
  alarm_sns_topic_arn   = module.sns_alerts.topic_arn
  iterator_age_threshold_ms = 60000
}

# ---------------------------------------------------------------------------
# Section 5: S3 Bucket — Dead-Letter Queue for failed embedding records
# ---------------------------------------------------------------------------
module "s3_dlq" {
  source = "../../tf-aws-s3"

  bucket_name  = "${local.prefix}-embedding-dlq"
  environment  = var.environment
  tags         = local.tags
  force_destroy = true

  versioning_enabled = true
  sse_algorithm      = var.enable_kms ? "aws:kms" : "AES256"
  kms_master_key_id  = local.kms_key_arn

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  lifecycle_rules = [
    {
      id      = "expire-failed-records"
      enabled = true
      expiration = {
        days = 90
      }
      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
    }
  ]
}

# ---------------------------------------------------------------------------
# Section 6: ECR Repositories (optional — for containerised Lambda)
# ---------------------------------------------------------------------------
module "ecr" {
  source = "../../tf-aws-ecr"

  name        = local.prefix
  environment = var.environment
  tags        = local.tags

  kms_key_arn = local.kms_key_arn

  repositories = {
    "embedding-lambda" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      force_delete         = false
      encryption_type      = var.enable_kms ? "KMS" : "AES256"
    }
    "chatbot-lambda" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      force_delete         = false
      encryption_type      = var.enable_kms ? "KMS" : "AES256"
    }
  }

  push_principal_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
}

# ---------------------------------------------------------------------------
# Section 7: IAM Role — Embedding Lambda
# ---------------------------------------------------------------------------
module "iam_embedding_lambda" {
  source = "../../tf-aws-iam-role"

  name        = "${local.prefix}-embedding-lambda"
  environment = var.environment
  tags        = local.tags
  description = "Execution role for the ${local.prefix} telemetry embedding Lambda"

  trusted_role_services = ["lambda.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  ]

  inline_policies = {
    kinesis-read = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "KinesisConsume"
          Effect = "Allow"
          Action = [
            "kinesis:GetRecords",
            "kinesis:GetShardIterator",
            "kinesis:DescribeStream",
            "kinesis:DescribeStreamSummary",
            "kinesis:ListShards",
            "kinesis:ListStreams",
          ]
          Resource = [module.kinesis.stream_arns["telemetry"]]
        }
      ]
    })

    bedrock-embed = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "BedrockEmbedding"
          Effect = "Allow"
          Action = ["bedrock:InvokeModel"]
          Resource = [
            "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.embedding_model_id}"
          ]
        }
      ]
    })

    opensearch-write = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "OpenSearchDataAccess"
          Effect   = "Allow"
          Action   = ["aoss:APIAccessAll"]
          Resource = [module.opensearch.collection_arn]
        }
      ]
    })

    s3-dlq-write = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "DLQWrite"
          Effect = "Allow"
          Action = ["s3:PutObject"]
          Resource = ["${module.s3_dlq.bucket_arn}/failed/*"]
        }
      ]
    })

    kms-use = var.enable_kms ? jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "KMSUse"
          Effect = "Allow"
          Action = [
            "kms:Decrypt",
            "kms:GenerateDataKey",
          ]
          Resource = [local.kms_key_arn]
        }
      ]
    }) : jsonencode({ Version = "2012-10-17", Statement = [] })
  }
}

# ---------------------------------------------------------------------------
# Section 8: IAM Role — Chatbot Lambda
# ---------------------------------------------------------------------------
module "iam_chatbot_lambda" {
  source = "../../tf-aws-iam-role"

  name        = "${local.prefix}-chatbot-lambda"
  environment = var.environment
  tags        = local.tags
  description = "Execution role for the ${local.prefix} RAG chatbot Lambda"

  trusted_role_services = ["lambda.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  ]

  inline_policies = {
    bedrock-invoke = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "BedrockInvoke"
          Effect = "Allow"
          Action = ["bedrock:InvokeModel"]
          Resource = [
            "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.embedding_model_id}",
            "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.llm_model_id}",
          ]
        }
      ]
    })

    opensearch-read = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "OpenSearchDataAccess"
          Effect   = "Allow"
          Action   = ["aoss:APIAccessAll"]
          Resource = [module.opensearch.collection_arn]
        }
      ]
    })

    kms-use = var.enable_kms ? jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "KMSUse"
          Effect = "Allow"
          Action = ["kms:Decrypt", "kms:GenerateDataKey"]
          Resource = [local.kms_key_arn]
        }
      ]
    }) : jsonencode({ Version = "2012-10-17", Statement = [] })
  }
}

# ---------------------------------------------------------------------------
# Section 9: OpenSearch Serverless — VECTORSEARCH collection
# ---------------------------------------------------------------------------
module "opensearch" {
  source = "../../tf-aws-opensearch"

  name        = "${local.prefix}-vs"
  environment = var.environment
  tags        = local.tags

  create_serverless = true
  create_domain     = false

  collection_type        = "VECTORSEARCH"
  collection_description = "EKS telemetry vector store for ${local.prefix} RAG chatbot"
  standby_replicas       = var.opensearch_standby_replicas

  kms_key_arn = local.kms_key_arn

  network_access_type = "PUBLIC"

  data_access_principals = [
    module.iam_embedding_lambda.role_arn,
    module.iam_chatbot_lambda.role_arn,
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
  ]
}

# ---------------------------------------------------------------------------
# Section 10: Bedrock — Guardrails + invocation logging
# ---------------------------------------------------------------------------
module "bedrock" {
  source = "../../tf-aws-bedrock"

  name        = local.prefix
  environment = var.environment
  tags        = local.tags

  enable_model_invocation_logging   = true
  invocation_log_s3_bucket          = module.s3_dlq.bucket_id
  invocation_log_s3_prefix          = "bedrock-invocation-logs/"
  invocation_log_retention_days     = var.log_retention_days
  kms_key_arn                       = local.kms_key_arn

  guardrails = var.enable_bedrock_guardrail ? {
    "observability" = {
      description            = "Prompt injection protection for ${local.prefix} RAG chatbot"
      blocked_input_message  = "Your request contains content that cannot be processed by this troubleshooting assistant."
      blocked_output_message = "The generated response was blocked by the content policy."
      kms_key_arn            = local.kms_key_arn

      content_policy_filters = [
        {
          type            = "PROMPT_ATTACK"
          input_strength  = "HIGH"
          output_strength = "NONE"
        },
        {
          type            = "MISCONDUCT"
          input_strength  = "MEDIUM"
          output_strength = "MEDIUM"
        },
      ]

      managed_word_lists = ["PROFANITY"]
      custom_words       = []

      sensitive_information_policy_config = [
        {
          type   = "EMAIL"
          action = "ANONYMIZE"
        },
        {
          type   = "AWS_ACCESS_KEY"
          action = "BLOCK"
        },
        {
          type   = "AWS_SECRET_KEY"
          action = "BLOCK"
        },
      ]
    }
  } : {}
}

# ---------------------------------------------------------------------------
# Section 11: Lambda — Embedding Pipeline
# ---------------------------------------------------------------------------
module "lambda_embedding" {
  source = "../../tf-aws-lambda"

  function_name = "${local.prefix}-telemetry-embedding"
  environment   = var.environment
  tags          = local.tags

  description  = "Normalizes EKS telemetry from Kinesis and generates Bedrock Titan embeddings stored in OpenSearch"
  runtime      = "python3.12"
  handler      = "embedding_handler.lambda_handler"
  timeout      = var.embedding_lambda_timeout
  memory_size  = var.embedding_lambda_memory_mb
  filename     = "${path.module}/lambda_src/embedding.zip"

  create_role = false
  role_arn    = module.iam_embedding_lambda.role_arn

  kms_key_arn = local.kms_key_arn

  log_retention_days = var.log_retention_days
  tracing_mode       = "Active"

  environment_variables = {
    OPENSEARCH_ENDPOINT = module.opensearch.collection_endpoint
    INDEX_NAME          = var.telemetry_index_name
    EMBEDDING_MODEL_ID  = var.embedding_model_id
    VECTOR_DIMENSIONS   = tostring(var.vector_dimensions)
    DLQ_BUCKET          = module.s3_dlq.bucket_id
    LOG_LEVEL           = "INFO"
  }

  # Kinesis event source mapping — triggers embedding on each batch
  event_source_mappings = {
    kinesis-telemetry = {
      event_source_arn                   = module.kinesis.stream_arns["telemetry"]
      batch_size                         = var.kinesis_batch_size
      starting_position                  = "LATEST"
      maximum_batching_window_in_seconds = 10
      bisect_batch_on_function_error     = true
      parallelization_factor             = 2
      maximum_retry_attempts             = 3
    }
  }

  create_cloudwatch_alarms = true
  alarm_sns_topic_arn      = module.sns_alerts.topic_arn
  alarm_error_threshold    = 5

  depends_on = [
    module.iam_embedding_lambda,
    module.opensearch,
    module.kinesis,
  ]
}

# ---------------------------------------------------------------------------
# Section 12: Lambda — Chatbot Backend
# ---------------------------------------------------------------------------
module "lambda_chatbot" {
  source = "../../tf-aws-lambda"

  function_name = "${local.prefix}-chatbot-backend"
  environment   = var.environment
  tags          = local.tags

  description = "RAG chatbot: embeds query via Bedrock, retrieves telemetry from OpenSearch, generates kubectl commands via Claude, iterates with troubleshooting agent"
  runtime     = "python3.12"
  handler     = "chatbot_handler.lambda_handler"
  timeout     = var.chatbot_lambda_timeout
  memory_size = var.chatbot_lambda_memory_mb
  filename    = "${path.module}/lambda_src/chatbot.zip"

  create_role = false
  role_arn    = module.iam_chatbot_lambda.role_arn

  kms_key_arn = local.kms_key_arn

  log_retention_days = var.log_retention_days
  tracing_mode       = "Active"

  # Enable Function URL for direct invocation from UI / kubectl agent
  create_function_url    = true
  function_url_auth_type = "AWS_IAM"

  environment_variables = {
    OPENSEARCH_ENDPOINT       = module.opensearch.collection_endpoint
    INDEX_NAME                = var.telemetry_index_name
    EMBEDDING_MODEL_ID        = var.embedding_model_id
    LLM_MODEL_ID              = var.llm_model_id
    BEDROCK_GUARDRAIL_ID      = var.enable_bedrock_guardrail ? module.bedrock.guardrail_ids["observability"] : ""
    BEDROCK_GUARDRAIL_VERSION = "DRAFT"
    LOG_LEVEL                 = "INFO"
  }

  create_cloudwatch_alarms = true
  alarm_sns_topic_arn      = module.sns_alerts.topic_arn
  alarm_error_threshold    = 1

  depends_on = [
    module.iam_chatbot_lambda,
    module.opensearch,
    module.bedrock,
  ]
}

# ---------------------------------------------------------------------------
# Section 13: SNS — Alert topic
# ---------------------------------------------------------------------------
module "sns_alerts" {
  source = "../../tf-aws-sns"

  name        = "${local.prefix}-observability-alerts"
  environment = var.environment
  tags        = local.tags

  display_name       = "${local.prefix} Observability Alerts"
  kms_master_key_id  = local.kms_key_arn

  subscriptions = var.alarm_email != null ? {
    email = {
      protocol = "email"
      endpoint = var.alarm_email
    }
  } : {}
}

# ---------------------------------------------------------------------------
# Section 14: CloudWatch Alarms
# ---------------------------------------------------------------------------
# Kinesis iterator age alarm — detects Embedding Lambda falling behind
resource "aws_cloudwatch_metric_alarm" "kinesis_iterator_age" {
  alarm_name          = "${local.prefix}-kinesis-iterator-age-high"
  alarm_description   = "Kinesis iterator age exceeds 5 minutes — embedding Lambda may be falling behind"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = 300
  statistic           = "Maximum"
  threshold           = 300000 # 5 minutes in milliseconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    StreamName = module.kinesis.stream_names["telemetry"]
  }

  alarm_actions = [module.sns_alerts.topic_arn]
  ok_actions    = [module.sns_alerts.topic_arn]

  tags = local.tags
}

# OpenSearch search latency alarm
resource "aws_cloudwatch_metric_alarm" "opensearch_search_latency" {
  alarm_name          = "${local.prefix}-opensearch-search-latency"
  alarm_description   = "OpenSearch search latency P99 exceeds 5 seconds"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "SearchLatency"
  namespace           = "AWS/AOSS"
  period              = 60
  extended_statistic  = "p99"
  threshold           = 5000
  treat_missing_data  = "notBreaching"

  dimensions = {
    CollectionId   = module.opensearch.collection_id
    CollectionName = module.opensearch.collection_name
    ClientId       = data.aws_caller_identity.current.account_id
  }

  alarm_actions = [module.sns_alerts.topic_arn]
  ok_actions    = [module.sns_alerts.topic_arn]

  tags = local.tags
}
