locals {
  name_prefix = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  # OpenSearch Serverless names must be 3-32 chars, lowercase, alphanumeric + hyphens
  collection_name = substr(lower(replace(local.name_prefix, "_", "-")), 0, 32)

  data_access_policy_name = var.data_access_policy_name != null ? var.data_access_policy_name : "${local.collection_name}-access"

  common_tags = merge(var.tags, {
    Name        = local.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ═══════════════════════════════════════════════════════════════════════════════
# OPENSEARCH SERVERLESS
# ═══════════════════════════════════════════════════════════════════════════════

# ── Encryption Security Policy ─────────────────────────────────────────────────
resource "aws_opensearchserverless_security_policy" "encryption" {
  count = var.create_serverless ? 1 : 0

  name        = "${local.collection_name}-enc"
  type        = "encryption"
  description = "Encryption policy for ${local.collection_name}"

  policy = jsonencode({
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${local.collection_name}"]
    }]
    AWSOwnedKey = var.kms_key_arn == null ? true : false
    KmsARN      = var.kms_key_arn
  })
}

# ── Network Security Policy ────────────────────────────────────────────────────
resource "aws_opensearchserverless_security_policy" "network" {
  count = var.create_serverless ? 1 : 0

  name        = "${local.collection_name}-net"
  type        = "network"
  description = "Network policy for ${local.collection_name}"

  policy = jsonencode([
    {
      Rules = [
        { ResourceType = "collection", Resource = ["collection/${local.collection_name}"] },
        { ResourceType = "dashboard", Resource = ["collection/${local.collection_name}"] }
      ]
      AllowFromPublic = var.network_access_type == "PUBLIC" ? true : false
      SourceVPCEs     = var.network_access_type == "VPC" ? [aws_opensearchserverless_vpc_endpoint.this[0].id] : null
    }
  ])
}

# ── VPC Endpoint (when network_access_type = VPC) ─────────────────────────────
resource "aws_opensearchserverless_vpc_endpoint" "this" {
  count = var.create_serverless && var.network_access_type == "VPC" ? 1 : 0

  name               = "${local.collection_name}-vpce"
  vpc_id             = var.vpc_id
  subnet_ids         = var.vpc_subnet_ids
  security_group_ids = var.vpc_security_group_ids
}

# ── Serverless Collection ──────────────────────────────────────────────────────
resource "aws_opensearchserverless_collection" "this" {
  count = var.create_serverless ? 1 : 0

  name             = local.collection_name
  type             = var.collection_type
  description      = var.collection_description
  standby_replicas = var.standby_replicas
  tags             = local.common_tags

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
  ]
}

# ── Data Access Policy ─────────────────────────────────────────────────────────
resource "aws_opensearchserverless_access_policy" "data" {
  count = var.create_serverless && length(var.data_access_principals) > 0 ? 1 : 0

  name        = local.data_access_policy_name
  type        = "data"
  description = "Data access policy for ${local.collection_name}"

  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index"
          Resource     = ["index/${local.collection_name}/*"]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument",
          ]
        },
        {
          ResourceType = "collection"
          Resource     = ["collection/${local.collection_name}"]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DeleteCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems",
          ]
        }
      ]
      Principal = var.data_access_principals
    }
  ])
}

# ═══════════════════════════════════════════════════════════════════════════════
# OPENSEARCH MANAGED DOMAIN
# ═══════════════════════════════════════════════════════════════════════════════

# ── CloudWatch Log Groups (managed domain) ─────────────────────────────────────
resource "aws_cloudwatch_log_group" "index_slow" {
  count = var.create_domain && var.enable_domain_logging ? 1 : 0

  name              = "/aws/opensearch/${local.name_prefix}/index-slow"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "search_slow" {
  count = var.create_domain && var.enable_domain_logging ? 1 : 0

  name              = "/aws/opensearch/${local.name_prefix}/search-slow"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "application" {
  count = var.create_domain && var.enable_domain_logging ? 1 : 0

  name              = "/aws/opensearch/${local.name_prefix}/application"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_resource_policy" "opensearch" {
  count = var.create_domain && var.enable_domain_logging ? 1 : 0

  policy_name = "${local.name_prefix}-opensearch-logs"
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "es.amazonaws.com" }
      Action    = ["logs:PutLogEvents", "logs:CreateLogStream"]
      Resource = [
        "${aws_cloudwatch_log_group.index_slow[0].arn}:*",
        "${aws_cloudwatch_log_group.search_slow[0].arn}:*",
        "${aws_cloudwatch_log_group.application[0].arn}:*",
      ]
    }]
  })
}

# ── OpenSearch Managed Domain ──────────────────────────────────────────────────
resource "aws_opensearch_domain" "this" {
  count = var.create_domain ? 1 : 0

  domain_name    = local.collection_name
  engine_version = var.engine_version
  tags           = local.common_tags

  cluster_config {
    instance_type            = var.instance_type
    instance_count           = var.instance_count
    dedicated_master_enabled = var.dedicated_master_enabled
    dedicated_master_type    = var.dedicated_master_enabled ? var.dedicated_master_type : null
    dedicated_master_count   = var.dedicated_master_enabled ? var.dedicated_master_count : null
    zone_awareness_enabled   = var.zone_awareness_enabled

    dynamic "zone_awareness_config" {
      for_each = var.zone_awareness_enabled ? [1] : []
      content {
        availability_zone_count = var.availability_zone_count
      }
    }
  }

  ebs_options {
    ebs_enabled = var.ebs_enabled
    volume_size = var.ebs_enabled ? var.ebs_volume_size_gb : null
    volume_type = var.ebs_enabled ? var.ebs_volume_type : null
  }

  dynamic "vpc_options" {
    for_each = length(var.domain_vpc_subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.domain_vpc_subnet_ids
      security_group_ids = var.domain_vpc_security_group_ids
    }
  }

  encrypt_at_rest {
    enabled    = var.enable_encrypt_at_rest
    kms_key_id = var.kms_key_arn
  }

  node_to_node_encryption {
    enabled = var.enable_node_to_node_encryption
  }

  domain_endpoint_options {
    enforce_https       = var.enforce_https
    tls_security_policy = var.tls_security_policy
  }

  snapshot_options {
    automated_snapshot_start_hour = var.automated_snapshot_start_hour
  }

  access_policies = var.domain_access_policy

  dynamic "log_publishing_options" {
    for_each = var.create_domain && var.enable_domain_logging ? [
      { type = "INDEX_SLOW_LOGS", arn = aws_cloudwatch_log_group.index_slow[0].arn },
      { type = "SEARCH_SLOW_LOGS", arn = aws_cloudwatch_log_group.search_slow[0].arn },
      { type = "ES_APPLICATION_LOGS", arn = aws_cloudwatch_log_group.application[0].arn },
    ] : []
    content {
      log_type                 = log_publishing_options.value.type
      cloudwatch_log_group_arn = log_publishing_options.value.arn
      enabled                  = true
    }
  }
}

resource "aws_opensearch_domain_policy" "this" {
  count = var.create_domain && var.domain_access_policy != null ? 1 : 0

  domain_name     = aws_opensearch_domain.this[0].domain_name
  access_policies = var.domain_access_policy
}
