# Amazon OpenSearch Service (Serverless + Managed Domain)

A production-ready Terraform module that provisions **Amazon OpenSearch Service** in two modes:

- **OpenSearch Serverless** (default) — zero-infrastructure vector store and analytics engine, ideal for RAG pipelines, semantic search with Bedrock embeddings, and event analytics. Billed per OCU-hour with no cluster to manage.
- **OpenSearch Managed Domain** (optional) — a persistent, EC2-backed domain for traditional full-text search, legacy Elasticsearch workloads, or scenarios that require fine-grained cluster control.

Set `create_serverless = false` and `create_domain = true` to switch to a managed domain.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     tf-aws-opensearch module                        │
│                                                                     │
│  Mode A — Serverless (default)        Mode B — Managed Domain       │
│  ─────────────────────────────        ──────────────────────────    │
│                                                                     │
│  ┌─────────────────────────┐          ┌────────────────────────┐   │
│  │  Encryption Policy      │          │  aws_opensearch_domain  │   │
│  │  (AWS-managed / CMK)    │          │  ┌──────────────────┐  │   │
│  └──────────┬──────────────┘          │  │  Cluster Config  │  │   │
│             │                         │  │  EBS Options     │  │   │
│  ┌──────────▼──────────────┐          │  │  VPC Options     │  │   │
│  │  Network Policy         │          │  │  Encrypt-at-rest │  │   │
│  │  PUBLIC or VPC endpoint │          │  │  Node-to-Node    │  │   │
│  └──────────┬──────────────┘          │  │  TLS Policy      │  │   │
│             │                         │  └──────────────────┘  │   │
│  ┌──────────▼──────────────┐          └────────────┬───────────┘   │
│  │  Serverless Collection  │                       │               │
│  │  VECTORSEARCH / SEARCH  │          ┌────────────▼───────────┐   │
│  │  TIMESERIES             │          │  CloudWatch Log Groups  │   │
│  └──────────┬──────────────┘          │  index-slow             │   │
│             │                         │  search-slow            │   │
│  ┌──────────▼──────────────┐          │  application            │   │
│  │  Data Access Policy     │          └────────────────────────┘   │
│  │  (IAM principals)       │                                        │
│  └─────────────────────────┘                                        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Usage Examples

### 1. VECTORSEARCH Collection for RAG (Lambda + Bedrock Embeddings)

The most common use case: a Lambda function calls Amazon Bedrock to generate embeddings and stores/queries them in OpenSearch Serverless.

```hcl
module "opensearch_rag" {
  source = "./tf-aws-opensearch"

  name        = "rag-store"
  name_prefix = "myapp-prod"
  environment = "prod"

  # Serverless VECTORSEARCH is the default
  create_serverless = true
  collection_type   = "VECTORSEARCH"
  standby_replicas  = "ENABLED"   # multi-AZ for production

  # Grant your Lambda execution role data access
  data_access_principals = [
    "arn:aws:iam::123456789012:role/my-rag-lambda-role",
    "arn:aws:iam::123456789012:role/my-bedrock-pipeline-role",
  ]

  tags = {
    Team       = "ml-platform"
    CostCenter = "ai-products"
  }
}

# Use the collection endpoint in your Lambda environment
output "opensearch_endpoint" {
  value = module.opensearch_rag.collection_endpoint
}
```

> **IAM note:** Principals listed in `data_access_principals` receive data-plane access via the OpenSearch data access policy. They also need `aoss:APIAccessAll` on the collection resource in their **IAM identity policy**. See the [IAM Permissions](#iam-permissions-note) section below.

---

### 2. TIMESERIES Collection for Log Analytics

Optimised for append-heavy time-series data such as application logs, metrics, and audit trails.

```hcl
module "opensearch_logs" {
  source = "./tf-aws-opensearch"

  name        = "log-analytics"
  name_prefix = "platform"
  environment = "prod"

  collection_type        = "TIMESERIES"
  collection_description = "Centralised log analytics store"
  standby_replicas       = "ENABLED"

  data_access_principals = [
    "arn:aws:iam::123456789012:role/log-ingestion-role",
    "arn:aws:iam::123456789012:role/grafana-query-role",
  ]

  tags = {
    Team = "platform"
  }
}
```

---

### 3. VPC-Private VECTORSEARCH Collection

Locks the collection inside your VPC — traffic never traverses the public internet.

```hcl
module "opensearch_private" {
  source = "./tf-aws-opensearch"

  name        = "private-vectors"
  name_prefix = "fintech-prod"
  environment = "prod"

  collection_type     = "VECTORSEARCH"
  network_access_type = "VPC"

  vpc_id                 = "vpc-0abc123def456789"
  vpc_subnet_ids         = ["subnet-0aa1111", "subnet-0bb2222"]
  vpc_security_group_ids = ["sg-0cc3333"]

  data_access_principals = [
    "arn:aws:iam::123456789012:role/internal-search-role",
  ]

  # Customer-managed KMS key
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  tags = {
    Compliance = "pci-dss"
  }
}

output "vpc_endpoint_id" {
  value = module.opensearch_private.vpc_endpoint_id
}
```

---

### 4. Managed Domain with Multi-AZ (Traditional Workload)

Use a persistent EC2-backed domain when you need cluster-level control, custom plugins, or a pre-existing Elasticsearch migration path.

```hcl
module "opensearch_domain" {
  source = "./tf-aws-opensearch"

  name        = "search-domain"
  name_prefix = "ecommerce-prod"
  environment = "prod"

  # Switch to managed domain mode
  create_serverless = false
  create_domain     = true

  engine_version = "OpenSearch_2.13"
  instance_type  = "r6g.large.search"
  instance_count = 3

  # Multi-AZ with dedicated masters
  zone_awareness_enabled   = true
  availability_zone_count  = 3
  dedicated_master_enabled = true
  dedicated_master_type    = "r6g.large.search"
  dedicated_master_count   = 3

  # Storage
  ebs_enabled        = true
  ebs_volume_size_gb = 100
  ebs_volume_type    = "gp3"

  # VPC placement
  domain_vpc_subnet_ids         = ["subnet-0aa1111", "subnet-0bb2222", "subnet-0cc3333"]
  domain_vpc_security_group_ids = ["sg-0dd4444"]

  # Security
  enable_encrypt_at_rest         = true
  enable_node_to_node_encryption = true
  enforce_https                  = true
  kms_key_arn                    = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  # Access policy (JSON)
  domain_access_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::123456789012:role/search-app-role" }
      Action    = "es:*"
      Resource  = "arn:aws:es:us-east-1:123456789012:domain/ecommerce-prod-search-domain/*"
    }]
  })

  # Logging
  enable_domain_logging = true
  log_retention_days    = 30

  tags = {
    Team = "search-engineering"
  }
}

output "domain_endpoint" {
  value = module.opensearch_domain.domain_endpoint
}
```

---

## Serverless Collection Naming Rules

OpenSearch Serverless enforces strict naming constraints on collection names:

| Rule | Detail |
|------|--------|
| Length | 3 to 32 characters |
| Characters | Lowercase letters, digits, and hyphens only |
| Start | Must begin with a lowercase letter |
| No underscores | Underscores are automatically converted to hyphens by this module |
| Truncation | Names longer than 32 characters are automatically truncated |

The module computes the final name as:
```
collection_name = substr(lower(replace("${name_prefix}-${name}", "_", "-")), 0, 32)
```

Keep `name_prefix` + `name` short to avoid silent truncation.

---

## Cost Note — Serverless

OpenSearch Serverless uses an **OCU (OpenSearch Compute Unit)** billing model:

| Resource | Minimum | Rate (us-east-1) | Minimum hourly cost |
|----------|---------|------------------|---------------------|
| Indexing OCUs | 2 | $0.12 / OCU-hr | $0.24 / hr |
| Search OCUs | 2 | $0.12 / OCU-hr | $0.24 / hr |
| Storage | — | $0.024 / GB-month | varies |

**A single idle collection costs approximately $0.24–$0.48/hour** (2–4 OCUs minimum, depending on workload). There is no "paused" state — collections bill continuously while active.

Use `standby_replicas = "DISABLED"` in dev/test environments to reduce to a single-AZ deployment (still billed at minimum OCU rates).

---

## IAM Permissions Note

Data access in OpenSearch Serverless is controlled by **two independent layers**:

1. **OpenSearch data access policy** — this module creates one automatically when `data_access_principals` is set. It grants fine-grained index and collection operations (`aoss:ReadDocument`, `aoss:WriteDocument`, etc.).

2. **IAM identity policy** — each principal in `data_access_principals` **also needs** the following permission in its own IAM policy, or calls will be denied at the IAM layer before reaching OpenSearch:

```json
{
  "Effect": "Allow",
  "Action": "aoss:APIAccessAll",
  "Resource": "arn:aws:aoss:REGION:ACCOUNT_ID:collection/COLLECTION_ID"
}
```

Both layers must allow the request. A principal missing either one will receive an access denied error.

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Base name for the OpenSearch collection or domain. | `string` | — | yes |
| `name_prefix` | Optional prefix prepended to all resource names. | `string` | `""` | no |
| `environment` | Deployment environment (dev, staging, prod). | `string` | `"dev"` | no |
| `project` | Project name tag. | `string` | `""` | no |
| `owner` | Owner tag. | `string` | `""` | no |
| `cost_center` | Cost center tag. | `string` | `""` | no |
| `tags` | Additional tags applied to all resources. | `map(string)` | `{}` | no |
| `create_serverless` | Create an OpenSearch Serverless collection. | `bool` | `true` | no |
| `create_domain` | Create an OpenSearch managed domain. | `bool` | `false` | no |
| `collection_type` | Serverless collection type: `VECTORSEARCH`, `SEARCH`, or `TIMESERIES`. | `string` | `"VECTORSEARCH"` | no |
| `collection_description` | Human-readable description of the serverless collection. | `string` | `"Managed by Terraform"` | no |
| `standby_replicas` | Serverless standby replicas: `ENABLED` (multi-AZ) or `DISABLED` (single-AZ). | `string` | `"ENABLED"` | no |
| `kms_key_arn` | KMS key ARN for encryption. Uses AWS-managed key when `null`. | `string` | `null` | no |
| `network_access_type` | Network access: `PUBLIC` or `VPC`. | `string` | `"PUBLIC"` | no |
| `vpc_id` | VPC ID for VPC endpoint. Required when `network_access_type = VPC`. | `string` | `null` | no |
| `vpc_subnet_ids` | Subnet IDs for the VPC endpoint. | `list(string)` | `[]` | no |
| `vpc_security_group_ids` | Security group IDs for the VPC endpoint. | `list(string)` | `[]` | no |
| `data_access_principals` | IAM principal ARNs granted full data access to the collection. | `list(string)` | `[]` | no |
| `data_access_policy_name` | Override name for the data access policy. Defaults to `<collection_name>-access`. | `string` | `null` | no |
| `engine_version` | OpenSearch engine version for managed domain. | `string` | `"OpenSearch_2.13"` | no |
| `instance_type` | EC2 instance type for managed domain data nodes. | `string` | `"r6g.large.search"` | no |
| `instance_count` | Number of data nodes in the managed domain. | `number` | `1` | no |
| `dedicated_master_enabled` | Enable dedicated master nodes. | `bool` | `false` | no |
| `dedicated_master_type` | Instance type for dedicated master nodes. | `string` | `"r6g.large.search"` | no |
| `dedicated_master_count` | Number of dedicated master nodes. | `number` | `3` | no |
| `zone_awareness_enabled` | Enable multi-AZ zone awareness. | `bool` | `false` | no |
| `availability_zone_count` | Number of AZs for zone-aware domain (2 or 3). | `number` | `2` | no |
| `ebs_enabled` | Enable EBS volumes for data node storage. | `bool` | `true` | no |
| `ebs_volume_size_gb` | EBS volume size in GB per data node. | `number` | `20` | no |
| `ebs_volume_type` | EBS volume type: `gp3`, `gp2`, `io1`. | `string` | `"gp3"` | no |
| `domain_vpc_subnet_ids` | Subnet IDs for managed domain VPC deployment. | `list(string)` | `[]` | no |
| `domain_vpc_security_group_ids` | Security group IDs for managed domain. | `list(string)` | `[]` | no |
| `domain_access_policy` | JSON access policy for the managed domain. | `string` | `null` | no |
| `enable_domain_logging` | Enable CloudWatch logging for the managed domain. | `bool` | `true` | no |
| `log_retention_days` | CloudWatch log retention in days. | `number` | `14` | no |
| `enable_encrypt_at_rest` | Enable encryption at rest for managed domain. | `bool` | `true` | no |
| `enable_node_to_node_encryption` | Enable node-to-node TLS encryption for managed domain. | `bool` | `true` | no |
| `enforce_https` | Require HTTPS for all traffic to managed domain. | `bool` | `true` | no |
| `tls_security_policy` | TLS security policy for managed domain. | `string` | `"Policy-Min-TLS-1-2-2019-07"` | no |
| `automated_snapshot_start_hour` | UTC hour for automated snapshot (0–23). | `number` | `1` | no |

---

## Outputs

| Name | Description | Populated when |
|------|-------------|----------------|
| `collection_id` | ID of the OpenSearch Serverless collection. | `create_serverless = true` |
| `collection_arn` | ARN of the OpenSearch Serverless collection. | `create_serverless = true` |
| `collection_endpoint` | Data endpoint URL for indexing and querying. | `create_serverless = true` |
| `dashboard_endpoint` | OpenSearch Dashboards URL for the serverless collection. | `create_serverless = true` |
| `collection_name` | Sanitized collection name (meets OpenSearch naming rules). | `create_serverless = true` |
| `vpc_endpoint_id` | VPC endpoint ID for private collection access. | `network_access_type = VPC` |
| `encryption_policy_name` | Name of the serverless encryption security policy. | `create_serverless = true` |
| `network_policy_name` | Name of the serverless network security policy. | `create_serverless = true` |
| `data_access_policy_name` | Name of the serverless data access policy. | `data_access_principals` non-empty |
| `domain_id` | ID of the OpenSearch managed domain. | `create_domain = true` |
| `domain_arn` | ARN of the OpenSearch managed domain. | `create_domain = true` |
| `domain_endpoint` | HTTPS endpoint for the OpenSearch managed domain. | `create_domain = true` |
| `kibana_endpoint` | OpenSearch Dashboards (Kibana) endpoint for the managed domain. | `create_domain = true` |
| `domain_name` | Name of the OpenSearch managed domain. | `create_domain = true` |
| `index_slow_log_group` | CloudWatch Log Group name for index slow logs. | `create_domain = true` and `enable_domain_logging = true` |

---

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws provider | >= 5.0 |

## License

MIT
