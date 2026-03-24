# ===========================================================================
# MODEL INVOCATION LOGGING
# ===========================================================================
resource "aws_cloudwatch_log_group" "bedrock" {
  count = var.enable_model_invocation_logging && var.invocation_log_cloudwatch_log_group == null ? 1 : 0

  name              = "/aws/bedrock/${local.name}"
  retention_in_days = var.invocation_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = local.tags
}

resource "aws_bedrock_model_invocation_logging_configuration" "this" {
  count = var.enable_model_invocation_logging ? 1 : 0

  logging_config {
    embedding_data_delivery_enabled = true
    image_data_delivery_enabled     = true
    text_data_delivery_enabled      = true

    dynamic "cloudwatch_config" {
      for_each = var.invocation_log_cloudwatch_log_group != null || var.enable_model_invocation_logging ? [1] : []
      content {
        log_group_name = coalesce(
          var.invocation_log_cloudwatch_log_group,
          try(aws_cloudwatch_log_group.bedrock[0].name, null)
        )
        role_arn = aws_iam_role.bedrock_logging[0].arn
      }
    }

    dynamic "s3_config" {
      for_each = var.invocation_log_s3_bucket != null ? [1] : []
      content {
        bucket_name = var.invocation_log_s3_bucket
        key_prefix  = var.invocation_log_s3_prefix
      }
    }
  }
}

resource "aws_iam_role" "bedrock_logging" {
  count = var.enable_model_invocation_logging ? 1 : 0
  name  = "${local.name}-bedrock-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "bedrock.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = local.account_id }
        ArnLike      = { "aws:SourceArn" = "arn:aws:bedrock:${local.region}:${local.account_id}:*" }
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "bedrock_logging" {
  count = var.enable_model_invocation_logging ? 1 : 0
  name  = "cloudwatch-logs"
  role  = aws_iam_role.bedrock_logging[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${try(aws_cloudwatch_log_group.bedrock[0].arn, "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/bedrock/*")}:*"
    }]
  })
}

# ===========================================================================
# GUARDRAILS
# ===========================================================================
resource "aws_bedrock_guardrail" "this" {
  for_each = var.guardrails

  name                      = "${local.name}-${each.key}"
  description               = each.value.description
  blocked_input_messaging   = each.value.blocked_input_message
  blocked_outputs_messaging = each.value.blocked_output_message
  kms_key_arn               = coalesce(each.value.kms_key_arn, var.kms_key_arn)

  dynamic "topic_policy_config" {
    for_each = length(each.value.topic_policy_topics) > 0 ? [1] : []
    content {
      dynamic "topics_config" {
        for_each = each.value.topic_policy_topics
        content {
          name       = topics_config.value.name
          definition = topics_config.value.definition
          type       = topics_config.value.type
          examples   = topics_config.value.examples
        }
      }
    }
  }

  dynamic "content_policy_config" {
    for_each = length(each.value.content_policy_filters) > 0 ? [1] : []
    content {
      dynamic "filters_config" {
        for_each = each.value.content_policy_filters
        content {
          type            = filters_config.value.type
          input_strength  = filters_config.value.input_strength
          output_strength = filters_config.value.output_strength
        }
      }
    }
  }

  dynamic "word_policy_config" {
    for_each = (length(each.value.managed_word_lists) > 0 || length(each.value.custom_words) > 0) ? [1] : []
    content {
      dynamic "managed_word_lists_config" {
        for_each = each.value.managed_word_lists
        content {
          type = managed_word_lists_config.value
        }
      }
      dynamic "words_config" {
        for_each = each.value.custom_words
        content {
          text = words_config.value
        }
      }
    }
  }

  dynamic "sensitive_information_policy_config" {
    for_each = length(each.value.sensitive_information_policy_config) > 0 ? [1] : []
    content {
      dynamic "pii_entities_config" {
        for_each = each.value.sensitive_information_policy_config
        content {
          type   = pii_entities_config.value.type
          action = pii_entities_config.value.action
        }
      }
    }
  }

  tags = local.tags
}

resource "aws_bedrock_guardrail_version" "this" {
  for_each      = var.guardrails
  guardrail_arn = aws_bedrock_guardrail.this[each.key].arn
  description   = "version managed by terraform"
}

# ===========================================================================
# KNOWLEDGE BASE IAM ROLE
# ===========================================================================
resource "aws_iam_role" "knowledge_base" {
  for_each = var.knowledge_bases
  name     = "${local.name}-kb-${each.key}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "bedrock.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = local.account_id }
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "knowledge_base" {
  for_each = var.knowledge_bases
  name     = "bedrock-kb-access"
  role     = aws_iam_role.knowledge_base[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = [each.value.embedding_model_arn]
      }],
      each.value.opensearch_collection_arn != null ? [{
        Effect   = "Allow"
        Action   = ["aoss:APIAccessAll"]
        Resource = [each.value.opensearch_collection_arn]
      }] : [],
      [for ds in each.value.s3_data_sources : {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [ds.bucket_arn, "${ds.bucket_arn}/*"]
      }]
    )
  })
}

# ===========================================================================
# KNOWLEDGE BASES
# ===========================================================================
resource "aws_bedrockagent_knowledge_base" "this" {
  for_each = var.knowledge_bases

  name        = "${local.name}-${each.key}"
  description = each.value.description
  role_arn    = aws_iam_role.knowledge_base[each.key].arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = each.value.embedding_model_arn
    }
  }

  storage_configuration {
    type = each.value.storage_type

    dynamic "opensearch_serverless_configuration" {
      for_each = each.value.storage_type == "OPENSEARCH_SERVERLESS" ? [1] : []
      content {
        collection_arn    = each.value.opensearch_collection_arn
        vector_index_name = each.value.opensearch_vector_index_name
        field_mapping {
          vector_field   = each.value.opensearch_field_mapping.vector_field
          text_field     = each.value.opensearch_field_mapping.text_field
          metadata_field = each.value.opensearch_field_mapping.metadata_field
        }
      }
    }
  }

  tags = local.tags
}

# S3 data sources for each knowledge base
resource "aws_bedrockagent_data_source" "this" {
  for_each = {
    for item in flatten([
      for kb_key, kb_val in var.knowledge_bases : [
        for idx, ds in kb_val.s3_data_sources : {
          key    = "${kb_key}-s3-${idx}"
          kb_key = kb_key
          ds     = ds
        }
      ]
    ]) : item.key => item
  }

  knowledge_base_id = aws_bedrockagent_knowledge_base.this[each.value.kb_key].id
  name              = "${local.name}-${each.key}"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn         = each.value.ds.bucket_arn
      inclusion_prefixes = length(each.value.ds.key_prefixes) > 0 ? each.value.ds.key_prefixes : null
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = each.value.ds.chunking_strategy
      dynamic "fixed_size_chunking_configuration" {
        for_each = each.value.ds.chunking_strategy == "FIXED_SIZE" ? [1] : []
        content {
          max_tokens         = each.value.ds.max_tokens
          overlap_percentage = each.value.ds.overlap_percentage
        }
      }
    }
  }
}

# ===========================================================================
# BEDROCK AGENT IAM ROLE
# ===========================================================================
resource "aws_iam_role" "agent" {
  for_each = var.agents
  name     = "AmazonBedrockExecutionRoleForAgents_${local.name}-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "bedrock.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = local.account_id }
        ArnLike      = { "aws:SourceArn" = "arn:aws:bedrock:${local.region}:${local.account_id}:agent/*" }
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "agent" {
  for_each = var.agents
  name     = "bedrock-agent-policy"
  role     = aws_iam_role.agent[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
        Resource = "arn:aws:bedrock:${local.region}::foundation-model/${each.value.foundation_model}"
      },
      {
        Effect   = "Allow"
        Action   = ["bedrock:Retrieve", "bedrock:RetrieveAndGenerate"]
        Resource = [for kb_id in each.value.knowledge_base_ids : "arn:aws:bedrock:${local.region}:${local.account_id}:knowledge-base/${kb_id}"]
      }
    ]
  })
}

# ===========================================================================
# BEDROCK AGENTS
# ===========================================================================
resource "aws_bedrockagent_agent" "this" {
  for_each = var.agents

  agent_name                  = "${local.name}-${each.key}"
  description                 = each.value.description
  foundation_model            = each.value.foundation_model
  instruction                 = each.value.instruction
  idle_session_ttl_in_seconds = each.value.idle_session_ttl
  agent_resource_role_arn     = aws_iam_role.agent[each.key].arn

  dynamic "guardrail_configuration" {
    for_each = each.value.guardrail_key != null ? [each.value.guardrail_key] : []
    content {
      guardrail_identifier = aws_bedrock_guardrail.this[guardrail_configuration.value].guardrail_id
      guardrail_version    = aws_bedrock_guardrail_version.this[guardrail_configuration.value].version
    }
  }

  tags = local.tags
}

# Action groups for agents
resource "aws_bedrockagent_agent_action_group" "this" {
  for_each = {
    for item in flatten([
      for agent_key, agent_val in var.agents : [
        for ag in agent_val.action_groups : {
          key       = "${agent_key}-${ag.name}"
          agent_key = agent_key
          ag        = ag
        }
      ]
    ]) : item.key => item
  }

  agent_id          = aws_bedrockagent_agent.this[each.value.agent_key].agent_id
  agent_version     = "DRAFT"
  action_group_name = each.value.ag.name
  description       = each.value.ag.description

  dynamic "action_group_executor" {
    for_each = each.value.ag.lambda_arn != null ? [1] : []
    content {
      lambda = each.value.ag.lambda_arn
    }
  }

  dynamic "api_schema" {
    for_each = each.value.ag.api_schema != null ? [each.value.ag.api_schema] : []
    content {
      s3 {
        s3_bucket_name = api_schema.value.s3_bucket
        s3_object_key  = api_schema.value.s3_key
      }
    }
  }
}

# Associate knowledge bases with agents
resource "aws_bedrockagent_agent_knowledge_base_association" "this" {
  for_each = {
    for item in flatten([
      for agent_key, agent_val in var.agents : [
        for kb_id in agent_val.knowledge_base_ids : {
          key       = "${agent_key}-${kb_id}"
          agent_key = agent_key
          kb_id     = kb_id
        }
      ]
    ]) : item.key => item
  }

  agent_id             = aws_bedrockagent_agent.this[each.value.agent_key].agent_id
  agent_version        = "DRAFT"
  knowledge_base_id    = each.value.kb_id
  description          = "Knowledge base association"
  knowledge_base_state = "ENABLED"
}
