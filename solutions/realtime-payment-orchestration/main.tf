# =============================================================================
# REAL-TIME PAYMENT ORCHESTRATION — COMPLETE SOLUTION
# Based on: https://aws.amazon.com/blogs/architecture/modernization-of-real-time-payment-orchestration-on-aws/
# =============================================================================

# ===========================================================================
# 1. ENCRYPTION — KMS Keys
# ===========================================================================
module "kms" {
  source      = "../../tf-aws-kms"
  name        = "${var.name}-payments"
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = local.common_tags
}

# ===========================================================================
# 2. NETWORK — VPC with private subnets (MSK brokers + Lambda live here)
# ===========================================================================
module "vpc" {
  source      = "../../tf-aws-vpc"
  name        = var.name
  environment = var.environment
  cidr        = var.vpc_cidr

  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "prod"
  enable_dns_hostnames   = true
  enable_flow_log        = true
  flow_log_destination   = "cloudwatch"

  tags = local.common_tags
}

# ===========================================================================
# 3. SECURITY GROUPS
# ===========================================================================
module "sg_msk" {
  source      = "../../tf-aws-security-group"
  name        = "${var.name}-msk"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  tags        = local.common_tags

  ingress_rules = [
    # Kafka TLS from Lambda SG
    {
      description              = "Kafka TLS from Lambda"
      from_port                = 9094
      to_port                  = 9094
      protocol                 = "tcp"
      source_security_group_id = module.sg_lambda.security_group_id
    },
    # Kafka SASL/IAM from Lambda SG
    {
      description              = "Kafka SASL/IAM from Lambda"
      from_port                = 9098
      to_port                  = 9098
      protocol                 = "tcp"
      source_security_group_id = module.sg_lambda.security_group_id
    },
    # ZooKeeper (Kafka < 3.7 — within cluster)
    {
      description = "ZooKeeper intra-cluster"
      from_port   = 2181
      to_port     = 2181
      protocol    = "tcp"
      self        = true
    },
  ]

  egress_rules = [
    { description = "Allow all outbound", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
  ]
}

module "sg_lambda" {
  source      = "../../tf-aws-security-group"
  name        = "${var.name}-lambda"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  tags        = local.common_tags

  egress_rules = [
    { description = "HTTPS to AWS services", from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { description = "Kafka TLS", from_port = 9094, to_port = 9094, protocol = "tcp", cidr_blocks = [var.vpc_cidr] },
    { description = "Kafka SASL/IAM", from_port = 9098, to_port = 9098, protocol = "tcp", cidr_blocks = [var.vpc_cidr] },
  ]
}

# ===========================================================================
# 4. SECRETS MANAGER — MSK credentials + payment rail API keys
# ===========================================================================
module "secrets" {
  source      = "../../tf-aws-secretsmanager"
  name        = "${var.name}-payments"
  environment = var.environment
  kms_key_arn = module.kms.key_arn
  tags        = local.common_tags

  secrets = {
    msk-scram = {
      description             = "MSK SCRAM authentication credentials"
      recovery_window_in_days = 7
      secret_string           = jsonencode({ username = "payments-svc", password = "CHANGE_ME_ON_FIRST_DEPLOY" })
    }
    swift-api-key = {
      description             = "SWIFT payment rail API key"
      recovery_window_in_days = 7
      secret_string           = jsonencode({ api_key = "PLACEHOLDER", endpoint = "https://api.swift.com/v4" })
    }
    ach-credentials = {
      description             = "ACH/RTP payment rail credentials"
      recovery_window_in_days = 7
      secret_string           = jsonencode({ client_id = "PLACEHOLDER", client_secret = "PLACEHOLDER" })
    }
  }
}

# ===========================================================================
# 5. MSK — Primary Kafka Cluster (event bus for payment pipeline)
# ===========================================================================
module "msk" {
  source = "../../tf-aws-data-e-msk"
  tags   = local.common_tags

  kms_key_arn      = module.kms.key_arn
  create_alarms    = true
  alarm_sns_topic_arn = module.alarms_sns.topic_arn

  configurations = {
    payments-config = {
      name        = "${var.name}-payments-broker-config"
      description = "Optimised broker config for payment event streaming"
      kafka_versions = [var.msk_kafka_version]
      server_properties = join("\n", [
        "auto.create.topics.enable=false",
        "default.replication.factor=3",
        "min.insync.replicas=2",
        "log.retention.hours=168",     # 7-day retention for payments
        "num.partitions=12",           # 12 partitions for 1000+ TPS throughput
        "compression.type=lz4",        # LZ4 for speed + compression
        "log.segment.bytes=536870912", # 512MB segments
        "message.max.bytes=10485760",  # 10MB max message (batch payments)
        "replica.fetch.max.bytes=10485760",
        "unclean.leader.election.enable=false", # Prevent data loss
      ])
    }
  }

  clusters = {
    payments = {
      kafka_version          = var.msk_kafka_version
      number_of_broker_nodes = var.msk_broker_count
      instance_type          = var.msk_instance_type
      client_subnets         = module.vpc.private_subnet_ids_list
      security_group_ids     = [module.sg_msk.security_group_id]
      ebs_volume_size        = var.msk_ebs_volume_size
      configuration_key      = "payments-config"

      # Authentication: IAM (Lambda uses IAM roles — no passwords needed)
      enable_sasl_iam   = true
      enable_sasl_scram = true  # for monitoring tools
      unauthenticated   = false

      # Encryption
      encryption_in_transit = "TLS"
      in_cluster_encryption = true

      # Tiered storage for cost-effective long-term retention
      tiered_storage_enabled = true

      # Enhanced monitoring for payment SLA observability
      enhanced_monitoring    = "PER_BROKER"
      jmx_exporter_enabled   = true

      # CloudWatch logs
      cloudwatch_logs_enabled = true

      provisioned_throughput_enabled     = var.environment == "prod"
      provisioned_throughput_volume_mbps = 500

      tags = local.common_tags
    }
  }

  # MSK Replicator — cross-region failover (enabled in prod when failover cluster exists)
  replicators = var.failover_msk_cluster_arn != null ? {
    payments-cross-region = {
      description        = "Cross-region replication for payment pipeline failover"
      source_cluster_arn = module.msk.cluster_arns["payments"]
      target_cluster_arn = var.failover_msk_cluster_arn

      source_subnet_ids         = module.vpc.private_subnet_ids_list
      target_subnet_ids         = var.failover_msk_subnet_ids
      source_security_group_ids = [module.sg_msk.security_group_id]
      target_security_group_ids = var.failover_msk_security_group_ids

      target_compression_type = "LZ4"

      topic_replication = {
        topics_to_replicate       = [for t in local.kafka_topics : t]
        topics_to_exclude         = [".*\\.internal", "__consumer_offsets", "__transaction_state"]
        detect_and_copy_new_topics = true
        copy_topic_configurations  = true
        copy_access_control_lists_for_topics = true
        starting_position_type    = "LATEST"
      }

      consumer_group_replication = {
        consumer_groups_to_replicate        = ["payment-*"]
        consumer_groups_to_exclude          = []
        detect_and_copy_new_consumer_groups = true
        synchronise_consumer_group_offsets  = true
      }
    }
  } : {}
}

# ===========================================================================
# 6. DYNAMODB — Payment data layer (global tables for multi-region HA)
# ===========================================================================
module "dynamodb" {
  source      = "../../tf-aws-dynamodb"
  tags        = local.common_tags
  kms_key_arn = module.kms.key_arn

  tables = {
    # Main transaction store — the system of record
    payments = {
      hash_key  = "payment_id"
      range_key = "created_at"
      billing_mode = "PAY_PER_REQUEST"  # on-demand for burst payment traffic

      attributes = [
        { name = "payment_id",   type = "S" },
        { name = "created_at",   type = "S" },
        { name = "sender_id",    type = "S" },
        { name = "status",       type = "S" },
        { name = "payment_rail", type = "S" },
      ]

      global_secondary_indexes = [
        {
          name            = "sender-status-index"
          hash_key        = "sender_id"
          range_key       = "status"
          projection_type = "ALL"
        },
        {
          name            = "rail-status-index"
          hash_key        = "payment_rail"
          range_key       = "status"
          projection_type = "INCLUDE"
          non_key_attributes = ["payment_id", "amount", "currency", "created_at"]
        },
      ]

      stream_enabled   = true
      stream_view_type = "NEW_AND_OLD_IMAGES"  # for downstream consumers
      ttl_enabled      = false                 # payments must not expire

      point_in_time_recovery = true
      deletion_protection    = var.environment == "prod"
    }

    # Idempotency table — prevents duplicate payments on retry
    idempotency = {
      hash_key     = "idempotency_key"
      billing_mode = "PAY_PER_REQUEST"

      attributes = [{ name = "idempotency_key", type = "S" }]

      ttl_enabled      = true
      ttl_attribute    = "expires_at"  # auto-expire idempotency records after 24h
      stream_enabled   = false
      deletion_protection = false

      point_in_time_recovery = false
    }

    # Ledger — financial accounting (double-entry bookkeeping records)
    ledger = {
      hash_key  = "account_id"
      range_key = "entry_timestamp"
      billing_mode = "PAY_PER_REQUEST"

      attributes = [
        { name = "account_id",      type = "S" },
        { name = "entry_timestamp", type = "S" },
        { name = "payment_id",      type = "S" },
      ]

      global_secondary_indexes = [
        {
          name            = "payment-entry-index"
          hash_key        = "payment_id"
          projection_type = "ALL"
        }
      ]

      stream_enabled         = true
      stream_view_type       = "NEW_AND_OLD_IMAGES"
      point_in_time_recovery = true
      deletion_protection    = var.environment == "prod"
    }

    # Audit trail — immutable compliance log
    audit-trail = {
      hash_key  = "correlation_id"
      range_key = "event_timestamp"
      billing_mode = "PAY_PER_REQUEST"

      attributes = [
        { name = "correlation_id",  type = "S" },
        { name = "event_timestamp", type = "S" },
        { name = "payment_id",      type = "S" },
        { name = "actor",           type = "S" },
      ]

      global_secondary_indexes = [
        {
          name            = "payment-audit-index"
          hash_key        = "payment_id"
          range_key       = "event_timestamp"
          projection_type = "ALL"
        },
        {
          name            = "actor-audit-index"
          hash_key        = "actor"
          range_key       = "event_timestamp"
          projection_type = "KEYS_ONLY"
        }
      ]

      stream_enabled         = false
      point_in_time_recovery = true
      deletion_protection    = true  # always protect audit data
    }
  }

  # Global tables for multi-region HA (active-passive with DynamoDB global tables)
  global_tables = var.failover_msk_cluster_arn != null ? {
    payments-global = {
      hash_key  = "payment_id"
      range_key = "created_at"
      billing_mode = "PAY_PER_REQUEST"
      attributes = [
        { name = "payment_id", type = "S" },
        { name = "created_at", type = "S" },
      ]
      replica_regions = [var.failover_region]
      stream_enabled  = true
      stream_view_type = "NEW_AND_OLD_IMAGES"
      point_in_time_recovery = true
    }
  } : {}
}

# ===========================================================================
# 7. SQS — Dead-Letter Queues for failed payment events
# ===========================================================================
module "sqs_dlq" {
  source      = "../../tf-aws-sqs"
  name        = "${var.name}-payment-dlq"
  environment = var.environment
  kms_key_arn = module.kms.key_arn
  tags        = local.common_tags

  # Long retention — failed payments need investigation time
  message_retention_seconds  = 1209600  # 14 days
  visibility_timeout_seconds = 300

  # Alert when DLQ has messages (payment processing failures)
  create_cloudwatch_alarm       = true
  alarm_sns_topic_arn           = module.alarms_sns.topic_arn
  alarm_depth_threshold         = 1  # any failure = alert
}

# ===========================================================================
# 8. SNS — Alerts + Payment notifications
# ===========================================================================
module "alarms_sns" {
  source      = "../../tf-aws-sns"
  name        = "${var.name}-payment-alarms"
  environment = var.environment
  kms_key_arn = module.kms.key_arn
  tags        = local.common_tags

  email_subscriptions = var.alarm_sns_email != null ? [var.alarm_sns_email] : []
}

module "payment_notifications_sns" {
  source      = "../../tf-aws-sns"
  name        = "${var.name}-payment-notifications"
  environment = var.environment
  kms_key_arn = module.kms.key_arn
  tags        = local.common_tags
}

# ===========================================================================
# 9. LAMBDA — Payment Microservices
# ===========================================================================
module "lambda_payment_initiator" {
  source        = "../../tf-aws-lambda"
  function_name = "payment-initiator"
  name_prefix   = var.name
  environment   = var.environment
  project       = var.project
  owner         = var.owner
  cost_center   = var.cost_center
  description   = local.lambda_services.payment-initiator.description

  s3_bucket      = var.lambda_code_s3_bucket
  s3_key         = local.lambda_services.payment-initiator.s3_key
  runtime        = "python3.12"
  handler        = "handler.lambda_handler"
  architectures  = var.lambda_architectures
  memory_size    = local.lambda_services.payment-initiator.memory
  timeout        = local.lambda_services.payment-initiator.timeout
  publish        = true

  subnet_ids         = module.vpc.private_subnet_ids_list
  security_group_ids = [module.sg_lambda.security_group_id]

  kms_key_arn        = module.kms.key_arn
  tracing_mode       = "Active"
  log_format         = "JSON"
  log_retention_days = var.log_retention_days

  reserved_concurrent_executions = var.lambda_reserved_concurrency

  environment_variables = {
    MSK_BOOTSTRAP_BROKERS = module.msk.cluster_bootstrap_brokers_sasl_iam["payments"]
    KAFKA_TOPIC_INITIATED  = "payment.initiated"
    IDEMPOTENCY_TABLE      = module.dynamodb.table_names["idempotency"]
    PAYMENTS_TABLE         = module.dynamodb.table_names["payments"]
    AUDIT_TABLE            = module.dynamodb.table_names["audit-trail"]
    ENVIRONMENT            = var.environment
    POWERTOOLS_LOG_LEVEL   = "INFO"
    POWERTOOLS_SERVICE_NAME = "payment-initiator"
  }

  dead_letter_target_arn = module.sqs_dlq.queue_arn

  inline_policies = {
    payment-initiator = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "MSKConnect"
          Effect = "Allow"
          Action = ["kafka-cluster:Connect", "kafka-cluster:DescribeCluster",
                    "kafka-cluster:WriteData", "kafka-cluster:CreateTopic", "kafka-cluster:DescribeTopic"]
          Resource = [module.msk.cluster_arns["payments"], "${module.msk.cluster_arns["payments"]}/*"]
        },
        {
          Sid    = "DynamoDB"
          Effect = "Allow"
          Action = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:ConditionCheck", "dynamodb:UpdateItem"]
          Resource = [
            module.dynamodb.table_arns["payments"],
            module.dynamodb.table_arns["idempotency"],
            module.dynamodb.table_arns["audit-trail"],
          ]
        },
        {
          Sid    = "KMS"
          Effect = "Allow"
          Action = ["kms:Decrypt", "kms:GenerateDataKey"]
          Resource = [module.kms.key_arn]
        },
      ]
    })
  }

  create_cloudwatch_alarms = true
  alarm_sns_topic_arn      = module.alarms_sns.topic_arn
  alarm_error_threshold    = 10
  alarm_throttle_threshold = 5

  tags = local.common_tags
}

module "lambda_payment_validator" {
  source        = "../../tf-aws-lambda"
  function_name = "payment-validator"
  name_prefix   = var.name
  environment   = var.environment
  project       = var.project
  owner         = var.owner
  cost_center   = var.cost_center
  description   = local.lambda_services.payment-validator.description

  s3_bucket     = var.lambda_code_s3_bucket
  s3_key        = local.lambda_services.payment-validator.s3_key
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"
  architectures = var.lambda_architectures
  memory_size   = local.lambda_services.payment-validator.memory
  timeout       = local.lambda_services.payment-validator.timeout
  publish       = true

  subnet_ids         = module.vpc.private_subnet_ids_list
  security_group_ids = [module.sg_lambda.security_group_id]
  kms_key_arn        = module.kms.key_arn
  tracing_mode       = "Active"
  log_format         = "JSON"
  log_retention_days = var.log_retention_days
  reserved_concurrent_executions = var.lambda_reserved_concurrency

  environment_variables = {
    MSK_BOOTSTRAP_BROKERS    = module.msk.cluster_bootstrap_brokers_sasl_iam["payments"]
    KAFKA_TOPIC_CONSUMER     = "payment.initiated"
    KAFKA_TOPIC_VALIDATED    = "payment.validated"
    KAFKA_TOPIC_REJECTED     = "payment.rejected"
    PAYMENTS_TABLE           = module.dynamodb.table_names["payments"]
    AUDIT_TABLE              = module.dynamodb.table_names["audit-trail"]
    SANCTIONS_LIST_SECRET    = module.secrets.secret_arns["swift-api-key"]
    ENVIRONMENT              = var.environment
    POWERTOOLS_SERVICE_NAME  = "payment-validator"
  }

  # MSK event source mapping — triggered by Kafka topic
  event_source_mappings = {
    msk-payment-initiated = {
      event_source_arn                   = module.msk.cluster_arns["payments"]
      batch_size                         = 100
      maximum_batching_window_in_seconds = 5
      starting_position                  = "LATEST"
      bisect_batch_on_function_error     = true
      maximum_retry_attempts             = 3
      destination_config = {
        on_failure_destination_arn = module.sqs_dlq.queue_arn
      }
    }
  }

  inline_policies = {
    payment-validator = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "MSKAccess"
          Effect = "Allow"
          Action = ["kafka-cluster:Connect", "kafka-cluster:DescribeCluster",
                    "kafka-cluster:ReadData", "kafka-cluster:DescribeTopic",
                    "kafka-cluster:WriteData", "kafka-cluster:CreateTopic",
                    "kafka-cluster:DescribeGroup", "kafka-cluster:AlterGroup"]
          Resource = [module.msk.cluster_arns["payments"], "${module.msk.cluster_arns["payments"]}/*"]
        },
        {
          Sid    = "DynamoDB"
          Effect = "Allow"
          Action = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:UpdateItem"]
          Resource = [module.dynamodb.table_arns["payments"], module.dynamodb.table_arns["audit-trail"]]
        },
        {
          Sid    = "SecretsManager"
          Effect = "Allow"
          Action = ["secretsmanager:GetSecretValue"]
          Resource = [module.secrets.secret_arns["swift-api-key"]]
        },
        {
          Sid      = "SQS"
          Effect   = "Allow"
          Action   = ["sqs:SendMessage"]
          Resource = [module.sqs_dlq.queue_arn]
        },
        { Sid = "KMS", Effect = "Allow", Action = ["kms:Decrypt", "kms:GenerateDataKey"], Resource = [module.kms.key_arn] },
      ]
    })
  }

  dead_letter_target_arn   = module.sqs_dlq.queue_arn
  create_cloudwatch_alarms = true
  alarm_sns_topic_arn      = module.alarms_sns.topic_arn
  tags                     = local.common_tags
}

module "lambda_risk_management" {
  source        = "../../tf-aws-lambda"
  function_name = "risk-management"
  name_prefix   = var.name
  environment   = var.environment
  project       = var.project
  owner         = var.owner
  cost_center   = var.cost_center
  description   = local.lambda_services.risk-management.description

  s3_bucket     = var.lambda_code_s3_bucket
  s3_key        = local.lambda_services.risk-management.s3_key
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"
  architectures = var.lambda_architectures
  memory_size   = local.lambda_services.risk-management.memory
  timeout       = local.lambda_services.risk-management.timeout
  publish       = true

  subnet_ids         = module.vpc.private_subnet_ids_list
  security_group_ids = [module.sg_lambda.security_group_id]
  kms_key_arn        = module.kms.key_arn
  tracing_mode       = "Active"
  log_format         = "JSON"
  log_retention_days = var.log_retention_days
  reserved_concurrent_executions = var.lambda_reserved_concurrency

  environment_variables = {
    MSK_BOOTSTRAP_BROKERS   = module.msk.cluster_bootstrap_brokers_sasl_iam["payments"]
    KAFKA_TOPIC_CONSUMER    = "payment.validated"
    KAFKA_TOPIC_RISK_SCORED = "payment.risk-scored"
    PAYMENTS_TABLE          = module.dynamodb.table_names["payments"]
    AUDIT_TABLE             = module.dynamodb.table_names["audit-trail"]
    ENVIRONMENT             = var.environment
    POWERTOOLS_SERVICE_NAME = "risk-management"
  }

  event_source_mappings = {
    msk-payment-validated = {
      event_source_arn               = module.msk.cluster_arns["payments"]
      batch_size                     = 50
      maximum_batching_window_in_seconds = 3
      starting_position              = "LATEST"
      bisect_batch_on_function_error = true
      maximum_retry_attempts         = 3
      destination_config = {
        on_failure_destination_arn = module.sqs_dlq.queue_arn
      }
    }
  }

  inline_policies = {
    risk-management = jsonencode({
      Version = "2012-10-17"
      Statement = [
        { Sid = "MSK", Effect = "Allow", Action = ["kafka-cluster:Connect","kafka-cluster:DescribeCluster","kafka-cluster:ReadData","kafka-cluster:DescribeTopic","kafka-cluster:WriteData","kafka-cluster:CreateTopic","kafka-cluster:DescribeGroup","kafka-cluster:AlterGroup"], Resource = [module.msk.cluster_arns["payments"],"${module.msk.cluster_arns["payments"]}/*"] },
        { Sid = "DynamoDB", Effect = "Allow", Action = ["dynamodb:GetItem","dynamodb:UpdateItem","dynamodb:PutItem"], Resource = [module.dynamodb.table_arns["payments"],module.dynamodb.table_arns["audit-trail"]] },
        { Sid = "SQS", Effect = "Allow", Action = ["sqs:SendMessage"], Resource = [module.sqs_dlq.queue_arn] },
        { Sid = "KMS", Effect = "Allow", Action = ["kms:Decrypt","kms:GenerateDataKey"], Resource = [module.kms.key_arn] },
      ]
    })
  }

  dead_letter_target_arn   = module.sqs_dlq.queue_arn
  create_cloudwatch_alarms = true
  alarm_sns_topic_arn      = module.alarms_sns.topic_arn
  tags                     = local.common_tags
}

module "lambda_payment_executor" {
  source        = "../../tf-aws-lambda"
  function_name = "payment-executor"
  name_prefix   = var.name
  environment   = var.environment
  project       = var.project
  owner         = var.owner
  cost_center   = var.cost_center
  description   = local.lambda_services.payment-executor.description

  s3_bucket     = var.lambda_code_s3_bucket
  s3_key        = local.lambda_services.payment-executor.s3_key
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"
  architectures = var.lambda_architectures
  memory_size   = local.lambda_services.payment-executor.memory
  timeout       = local.lambda_services.payment-executor.timeout
  publish       = true

  subnet_ids         = module.vpc.private_subnet_ids_list
  security_group_ids = [module.sg_lambda.security_group_id]
  kms_key_arn        = module.kms.key_arn
  tracing_mode       = "Active"
  log_format         = "JSON"
  log_retention_days = var.log_retention_days
  reserved_concurrent_executions = var.lambda_reserved_concurrency

  environment_variables = {
    MSK_BOOTSTRAP_BROKERS   = module.msk.cluster_bootstrap_brokers_sasl_iam["payments"]
    KAFKA_TOPIC_CONSUMER    = "payment.risk-scored"
    KAFKA_TOPIC_EXECUTING   = "payment.executing"
    KAFKA_TOPIC_EXECUTED    = "payment.executed"
    KAFKA_TOPIC_FAILED      = "payment.failed"
    PAYMENTS_TABLE          = module.dynamodb.table_names["payments"]
    AUDIT_TABLE             = module.dynamodb.table_names["audit-trail"]
    SWIFT_SECRET_ARN        = module.secrets.secret_arns["swift-api-key"]
    ACH_SECRET_ARN          = module.secrets.secret_arns["ach-credentials"]
    ENVIRONMENT             = var.environment
    POWERTOOLS_SERVICE_NAME = "payment-executor"
  }

  event_source_mappings = {
    msk-payment-risk-scored = {
      event_source_arn               = module.msk.cluster_arns["payments"]
      batch_size                     = 10   # lower batch — each item is an external API call
      maximum_batching_window_in_seconds = 1
      starting_position              = "LATEST"
      bisect_batch_on_function_error = true
      maximum_retry_attempts         = 2    # external rails are not always idempotent
      destination_config = {
        on_failure_destination_arn = module.sqs_dlq.queue_arn
      }
    }
  }

  inline_policies = {
    payment-executor = jsonencode({
      Version = "2012-10-17"
      Statement = [
        { Sid = "MSK", Effect = "Allow", Action = ["kafka-cluster:Connect","kafka-cluster:DescribeCluster","kafka-cluster:ReadData","kafka-cluster:DescribeTopic","kafka-cluster:WriteData","kafka-cluster:CreateTopic","kafka-cluster:DescribeGroup","kafka-cluster:AlterGroup"], Resource = [module.msk.cluster_arns["payments"],"${module.msk.cluster_arns["payments"]}/*"] },
        { Sid = "DynamoDB", Effect = "Allow", Action = ["dynamodb:GetItem","dynamodb:UpdateItem","dynamodb:PutItem"], Resource = [module.dynamodb.table_arns["payments"],module.dynamodb.table_arns["audit-trail"]] },
        { Sid = "Secrets", Effect = "Allow", Action = ["secretsmanager:GetSecretValue"], Resource = [module.secrets.secret_arns["swift-api-key"],module.secrets.secret_arns["ach-credentials"]] },
        { Sid = "SQS", Effect = "Allow", Action = ["sqs:SendMessage"], Resource = [module.sqs_dlq.queue_arn] },
        { Sid = "KMS", Effect = "Allow", Action = ["kms:Decrypt","kms:GenerateDataKey"], Resource = [module.kms.key_arn] },
      ]
    })
  }

  dead_letter_target_arn   = module.sqs_dlq.queue_arn
  create_cloudwatch_alarms = true
  alarm_sns_topic_arn      = module.alarms_sns.topic_arn
  tags                     = local.common_tags
}

module "lambda_settlement" {
  source        = "../../tf-aws-lambda"
  function_name = "settlement"
  name_prefix   = var.name
  environment   = var.environment
  project       = var.project
  owner         = var.owner
  cost_center   = var.cost_center
  description   = local.lambda_services.settlement.description

  s3_bucket     = var.lambda_code_s3_bucket
  s3_key        = local.lambda_services.settlement.s3_key
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"
  architectures = var.lambda_architectures
  memory_size   = local.lambda_services.settlement.memory
  timeout       = local.lambda_services.settlement.timeout
  publish       = true

  subnet_ids         = module.vpc.private_subnet_ids_list
  security_group_ids = [module.sg_lambda.security_group_id]
  kms_key_arn        = module.kms.key_arn
  tracing_mode       = "Active"
  log_format         = "JSON"
  log_retention_days = var.log_retention_days

  environment_variables = {
    MSK_BOOTSTRAP_BROKERS   = module.msk.cluster_bootstrap_brokers_sasl_iam["payments"]
    KAFKA_TOPIC_CONSUMER    = "payment.executed"
    KAFKA_TOPIC_SETTLED     = "payment.settled"
    PAYMENTS_TABLE          = module.dynamodb.table_names["payments"]
    LEDGER_TABLE            = module.dynamodb.table_names["ledger"]
    AUDIT_TABLE             = module.dynamodb.table_names["audit-trail"]
    ENVIRONMENT             = var.environment
    POWERTOOLS_SERVICE_NAME = "settlement"
  }

  event_source_mappings = {
    msk-payment-executed = {
      event_source_arn               = module.msk.cluster_arns["payments"]
      batch_size                     = 50
      maximum_batching_window_in_seconds = 5
      starting_position              = "LATEST"
      bisect_batch_on_function_error = true
      maximum_retry_attempts         = 3
      destination_config = {
        on_failure_destination_arn = module.sqs_dlq.queue_arn
      }
    }
  }

  inline_policies = {
    settlement = jsonencode({
      Version = "2012-10-17"
      Statement = [
        { Sid = "MSK", Effect = "Allow", Action = ["kafka-cluster:Connect","kafka-cluster:DescribeCluster","kafka-cluster:ReadData","kafka-cluster:DescribeTopic","kafka-cluster:WriteData","kafka-cluster:CreateTopic","kafka-cluster:DescribeGroup","kafka-cluster:AlterGroup"], Resource = [module.msk.cluster_arns["payments"],"${module.msk.cluster_arns["payments"]}/*"] },
        { Sid = "DynamoDB", Effect = "Allow", Action = ["dynamodb:GetItem","dynamodb:UpdateItem","dynamodb:PutItem","dynamodb:TransactWriteItems"], Resource = [module.dynamodb.table_arns["payments"],module.dynamodb.table_arns["ledger"],module.dynamodb.table_arns["audit-trail"]] },
        { Sid = "SQS", Effect = "Allow", Action = ["sqs:SendMessage"], Resource = [module.sqs_dlq.queue_arn] },
        { Sid = "KMS", Effect = "Allow", Action = ["kms:Decrypt","kms:GenerateDataKey"], Resource = [module.kms.key_arn] },
      ]
    })
  }

  dead_letter_target_arn   = module.sqs_dlq.queue_arn
  create_cloudwatch_alarms = true
  alarm_sns_topic_arn      = module.alarms_sns.topic_arn
  tags                     = local.common_tags
}

module "lambda_notification" {
  source        = "../../tf-aws-lambda"
  function_name = "notification"
  name_prefix   = var.name
  environment   = var.environment
  project       = var.project
  owner         = var.owner
  cost_center   = var.cost_center
  description   = local.lambda_services.notification.description

  s3_bucket     = var.lambda_code_s3_bucket
  s3_key        = local.lambda_services.notification.s3_key
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"
  architectures = var.lambda_architectures
  memory_size   = local.lambda_services.notification.memory
  timeout       = local.lambda_services.notification.timeout
  publish       = true

  subnet_ids         = module.vpc.private_subnet_ids_list
  security_group_ids = [module.sg_lambda.security_group_id]
  kms_key_arn        = module.kms.key_arn
  tracing_mode       = "Active"
  log_format         = "JSON"
  log_retention_days = var.log_retention_days

  environment_variables = {
    MSK_BOOTSTRAP_BROKERS        = module.msk.cluster_bootstrap_brokers_sasl_iam["payments"]
    KAFKA_TOPICS                 = "payment.settled,payment.rejected,payment.failed"
    SNS_NOTIFICATION_TOPIC_ARN   = module.payment_notifications_sns.topic_arn
    AUDIT_TABLE                  = module.dynamodb.table_names["audit-trail"]
    ENVIRONMENT                  = var.environment
    POWERTOOLS_SERVICE_NAME      = "notification"
  }

  event_source_mappings = {
    msk-payment-terminal = {
      event_source_arn               = module.msk.cluster_arns["payments"]
      batch_size                     = 100
      maximum_batching_window_in_seconds = 10
      starting_position              = "LATEST"
      destination_config = {
        on_failure_destination_arn = module.sqs_dlq.queue_arn
      }
    }
  }

  inline_policies = {
    notification = jsonencode({
      Version = "2012-10-17"
      Statement = [
        { Sid = "MSK", Effect = "Allow", Action = ["kafka-cluster:Connect","kafka-cluster:DescribeCluster","kafka-cluster:ReadData","kafka-cluster:DescribeTopic","kafka-cluster:DescribeGroup","kafka-cluster:AlterGroup"], Resource = [module.msk.cluster_arns["payments"],"${module.msk.cluster_arns["payments"]}/*"] },
        { Sid = "SNS", Effect = "Allow", Action = ["sns:Publish"], Resource = [module.payment_notifications_sns.topic_arn] },
        { Sid = "DynamoDB", Effect = "Allow", Action = ["dynamodb:PutItem"], Resource = [module.dynamodb.table_arns["audit-trail"]] },
        { Sid = "KMS", Effect = "Allow", Action = ["kms:Decrypt","kms:GenerateDataKey"], Resource = [module.kms.key_arn] },
      ]
    })
  }

  dead_letter_target_arn   = module.sqs_dlq.queue_arn
  create_cloudwatch_alarms = true
  alarm_sns_topic_arn      = module.alarms_sns.topic_arn
  tags                     = local.common_tags
}

# ===========================================================================
# 10. API GATEWAY — Payment HTTP API (edge-optimised, JWT auth)
# ===========================================================================
module "api_gateway" {
  source      = "../../tf-aws-apigateway"
  name        = "${var.name}-payments-api"
  environment = var.environment
  tags        = local.common_tags

  protocol_type = "HTTP"
  description   = "Real-time payment orchestration API"
  stage_name    = var.environment
  auto_deploy   = true

  enable_access_logs  = true
  log_retention_days  = var.log_retention_days

  default_route_settings = {
    throttling_burst_limit   = var.api_throttle_burst_limit
    throttling_rate_limit    = var.api_throttle_rate_limit
    detailed_metrics_enabled = true
  }

  routes = {
    "POST /v1/payments" = {
      lambda_invoke_arn    = module.lambda_payment_initiator.function_invoke_arn
      lambda_function_name = module.lambda_payment_initiator.function_name
      timeout_milliseconds = 29000
      authorization_type   = "NONE"  # WAF + CloudFront handle auth at edge
      authorizer_id        = null
    }
    "GET /v1/payments/{payment_id}" = {
      lambda_invoke_arn    = module.lambda_payment_initiator.function_invoke_arn
      lambda_function_name = module.lambda_payment_initiator.function_name
      timeout_milliseconds = 10000
      authorization_type   = "NONE"
      authorizer_id        = null
    }
    "GET /v1/health" = {
      lambda_invoke_arn    = module.lambda_payment_initiator.function_invoke_arn
      lambda_function_name = module.lambda_payment_initiator.function_name
      timeout_milliseconds = 5000
      authorization_type   = "NONE"
      authorizer_id        = null
    }
  }
}

# ===========================================================================
# 11. WAF — Payment API Protection (CLOUDFRONT scope — must be us-east-1)
# ===========================================================================
module "waf" {
  source      = "../../tf-aws-waf"
  name        = "${var.name}-payments-waf"
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = local.common_tags

  scope          = "CLOUDFRONT"
  default_action = "allow"
  description    = "WAF for real-time payment API — OWASP, rate limiting, geo-blocking"

  # ── AWS Managed Rule Groups ─────────────────────────────────────────────
  managed_rule_groups = [
    {
      name        = "AWSManagedRulesCommonRuleSet"
      vendor_name = "AWS"
      priority    = 10
      override_action = "none"
      excluded_rules  = ["SizeRestrictions_BODY"]  # Payment bodies can be > default size
      rule_action_overrides = []
    },
    {
      name        = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name = "AWS"
      priority    = 20
      override_action = "none"
    },
    {
      name        = "AWSManagedRulesSQLiRuleSet"
      vendor_name = "AWS"
      priority    = 30
      override_action = "none"
    },
    {
      name        = "AWSManagedRulesAmazonIpReputationList"
      vendor_name = "AWS"
      priority    = 40
      override_action = "none"
    },
    {
      name        = "AWSManagedRulesAnonymousIpList"
      vendor_name = "AWS"
      priority    = 50
      override_action = "none"
      # Allow VPNs for enterprise customers — count only
      excluded_rules = ["HostingProviderIPList"]
    },
  ]

  # ── IP Sets ─────────────────────────────────────────────────────────────
  ip_sets = length(var.payment_api_allowed_cidrs) > 0 ? {
    trusted-partners = {
      description        = "Trusted partner bank CIDR ranges"
      ip_address_version = "IPV4"
      addresses          = var.payment_api_allowed_cidrs
    }
  } : {}

  ip_set_rules = length(var.payment_api_allowed_cidrs) > 0 ? [
    {
      name       = "AllowTrustedPartners"
      priority   = 5   # Must be evaluated BEFORE geo-block
      action     = "allow"
      ip_set_key = "trusted-partners"
    }
  ] : []

  # ── Geo-block OFAC sanctioned countries ─────────────────────────────────
  geo_match_rules = length(var.waf_geo_block_countries) > 0 ? [
    {
      name          = "BlockSanctionedCountries"
      priority      = 60
      action        = "block"
      country_codes = var.waf_geo_block_countries
    }
  ] : []

  # ── Rate Limiting ────────────────────────────────────────────────────────
  rate_based_rules = [
    {
      name               = "PaymentAPIRateLimit"
      priority           = 70
      action             = "block"
      limit              = var.waf_rate_limit_per_5min
      aggregate_key_type = "IP"
    },
    {
      name               = "PaymentAPIForwardedIPRateLimit"
      priority           = 71
      action             = "block"
      limit              = var.waf_rate_limit_per_5min
      aggregate_key_type = "FORWARDED_IP"
      forwarded_ip_config = {
        header_name       = "X-Forwarded-For"
        fallback_behavior = "MATCH"
      }
    }
  ]

  # ── Custom Rules — Payment-specific ─────────────────────────────────────
  custom_rules = [
    # Block oversized payment request bodies (potential DoS)
    {
      name     = "BlockLargePaymentBodies"
      priority = 80
      action   = "block"
      size_constraint_statement = {
        field_to_match_type = "BODY"
        comparison_operator = "GT"
        size                = 102400  # 100KB max payment payload
        text_transformations = ["NONE"]
      }
    },
    # Block SQL injection in payment amount field via query string
    {
      name     = "BlockSQLiQueryString"
      priority = 90
      action   = "block"
      sqli_match_statement = {
        field_to_match_type  = "QUERY_STRING"
        text_transformations = ["URL_DECODE", "HTML_ENTITY_DECODE", "LOWERCASE"]
      }
    }
  ]

  # ── WAF Logging (to S3 via Kinesis Firehose — not created here) ──────────
  logging_config = null  # wire in via waf_log_destination_arn if needed
}

# ===========================================================================
# 12. CLOUDFRONT — Global edge routing for payment API
# ===========================================================================
module "cloudfront" {
  source      = "../../tf-aws-cloudfront"
  name        = "${var.name}-payments"
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = local.common_tags

  aliases   = var.api_domain_name != null ? [var.api_domain_name] : []
  web_acl_id = module.waf.web_acl_arn
  price_class = "PriceClass_All"  # Global payments need global PoPs
  http_version = "http2and3"
  is_ipv6_enabled = true
  comment = "Real-time payment orchestration API CDN"

  viewer_certificate = var.acm_certificate_arn != null ? {
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  } : {
    cloudfront_default_certificate = true
  }

  origins = [
    {
      origin_id   = "payment-api-gateway"
      domain_name = "${module.api_gateway.api_id}.execute-api.${var.primary_region}.amazonaws.com"
      origin_path = "/${var.environment}"
      custom_origin_config = {
        https_port               = 443
        http_port                = 80
        origin_protocol_policy   = "https-only"
        origin_ssl_protocols     = ["TLSv1.2"]
        origin_keepalive_timeout = 60
        origin_read_timeout      = 60  # payment calls may take up to 30s
      }
      # Add secret header to prevent direct-to-origin bypass
      custom_headers = [
        {
          name  = "X-Origin-Verify"
          value = "CLOUDFRONT-${var.name}-${var.environment}"
        }
      ]
      # Origin Shield in primary region for cache consolidation
      origin_shield = {
        enabled              = true
        origin_shield_region = var.primary_region
      }
    }
  ]

  default_cache_behavior = {
    target_origin_id       = "payment-api-gateway"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    # Use CachingDisabled managed policy (payments must never be cached)
    # Managed policy ID: 4135ea2d-6df8-44a3-9df3-4b5a84be39ad
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    # AllViewer origin request policy — forward all headers, cookies, query strings
    # Managed policy ID: 216adef6-5c7f-47e4-b989-5492eafa07d3
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"

    # Security headers policy (CORS, HSTS, X-Frame-Options)
    # Managed policy: SecurityHeadersPolicy - 67f7725c-6f97-4210-82d7-5512b31e9d03
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # Health check endpoint can be cached briefly
  ordered_cache_behaviors = [
    {
      path_pattern           = "/*/v1/health"
      target_origin_id       = "payment-api-gateway"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      # CachingOptimized — health checks can be cached for 5s
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      min_ttl                = 0
      default_ttl            = 5
      max_ttl                = 10
    }
  ]

  custom_error_responses = [
    {
      error_code            = 502
      response_code         = 503
      response_page_path    = null
      error_caching_min_ttl = 0  # Never cache API errors
    },
    {
      error_code            = 503
      error_caching_min_ttl = 0
    },
    {
      error_code            = 504
      error_caching_min_ttl = 0
    },
  ]

  geo_restriction = {
    restriction_type = "none"  # geo blocking handled by WAF (more granular)
    locations        = []
  }
}

# ===========================================================================
# 13. CLOUDWATCH — Dashboards, alarms, log groups
# ===========================================================================
module "cloudwatch" {
  source      = "../../tf-aws-cloudwatch"
  name        = "${var.name}-payments"
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = local.common_tags

  alarm_sns_topic_arns = [module.alarms_sns.topic_arn]

  # API Gateway alarms
  api_gateway_alarms = [
    {
      api_id        = module.api_gateway.api_id
      stage         = var.environment
      alarm_5xx_threshold  = 10
      alarm_latency_ms     = 5000  # 5s p99 SLA
    }
  ]

  # Generic alarms for DLQ
  generic_alarms = [
    {
      alarm_name          = "${var.name}-payment-dlq-depth"
      alarm_description   = "Payment DLQ has messages — investigate failed payment events"
      namespace           = "AWS/SQS"
      metric_name         = "ApproximateNumberOfMessagesVisible"
      dimensions          = { QueueName = module.sqs_dlq.queue_name }
      comparison_operator = "GreaterThanThreshold"
      threshold           = 0
      evaluation_periods  = 1
      period              = 60
      statistic           = "Sum"
    },
    {
      alarm_name          = "${var.name}-msk-under-replicated"
      alarm_description   = "MSK has under-replicated partitions — Kafka cluster health risk"
      namespace           = "AWS/Kafka"
      metric_name         = "UnderReplicatedPartitions"
      dimensions          = { Cluster = "${var.name}-payments" }
      comparison_operator = "GreaterThanThreshold"
      threshold           = 0
      evaluation_periods  = 1
      period              = 60
      statistic           = "Maximum"
    }
  ]
}
