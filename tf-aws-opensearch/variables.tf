variable "name" {
  description = "Base name for the OpenSearch collection or domain."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix prepended to all resource names."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "project" {
  type    = string
  default = ""
}

variable "owner" {
  type    = string
  default = ""
}

variable "cost_center" {
  type    = string
  default = ""
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

# ── Mode Selection ─────────────────────────────────────────────────────────────
variable "create_serverless" {
  description = "Create an OpenSearch Serverless collection. Recommended for RAG vector stores and event analytics."
  type        = bool
  default     = true
}

variable "create_domain" {
  description = "Create an OpenSearch managed domain. Set create_serverless = false when using this."
  type        = bool
  default     = false
}

# ── Serverless Collection ──────────────────────────────────────────────────────
variable "collection_type" {
  description = "Serverless collection type: VECTORSEARCH (RAG/embeddings), SEARCH (full-text), TIMESERIES (log analytics)."
  type        = string
  default     = "VECTORSEARCH"
  validation {
    condition     = contains(["VECTORSEARCH", "SEARCH", "TIMESERIES"], var.collection_type)
    error_message = "collection_type must be VECTORSEARCH, SEARCH, or TIMESERIES."
  }
}

variable "collection_description" {
  description = "Human-readable description of the serverless collection."
  type        = string
  default     = "Managed by Terraform"
}

variable "standby_replicas" {
  description = "Serverless standby replicas mode: ENABLED (multi-AZ, production) or DISABLED (single-AZ, dev/test)."
  type        = string
  default     = "ENABLED"
  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.standby_replicas)
    error_message = "standby_replicas must be ENABLED or DISABLED."
  }
}

# ── Encryption (Serverless) ────────────────────────────────────────────────────
variable "kms_key_arn" {
  description = "KMS key ARN for encrypting the collection. Uses AWS-managed key when null."
  type        = string
  default     = null
}

# ── Network Access (Serverless) ───────────────────────────────────────────────
variable "network_access_type" {
  description = "Network access for the collection: PUBLIC (internet), VPC (private endpoint)."
  type        = string
  default     = "PUBLIC"
  validation {
    condition     = contains(["PUBLIC", "VPC"], var.network_access_type)
    error_message = "network_access_type must be PUBLIC or VPC."
  }
}

variable "vpc_id" {
  description = "VPC ID for VPC endpoint. Required when network_access_type = VPC."
  type        = string
  default     = null
}

variable "vpc_subnet_ids" {
  description = "Subnet IDs for the VPC endpoint. Required when network_access_type = VPC."
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for the VPC endpoint."
  type        = list(string)
  default     = []
}

# ── Data Access Policy (Serverless) ───────────────────────────────────────────
variable "data_access_principals" {
  description = <<-EOT
    IAM principals (role ARNs, user ARNs) granted full data access to the collection.
    These principals can read/write indexes and run queries.
    Example: ["arn:aws:iam::123456789012:role/my-lambda-role"]
  EOT
  type    = list(string)
  default = []
}

variable "data_access_policy_name" {
  description = "Name for the serverless data access policy. Defaults to name."
  type        = string
  default     = null
}

# ── Managed Domain ─────────────────────────────────────────────────────────────
variable "engine_version" {
  description = "OpenSearch engine version for managed domain."
  type        = string
  default     = "OpenSearch_2.13"
}

variable "instance_type" {
  description = "EC2 instance type for managed domain data nodes."
  type        = string
  default     = "r6g.large.search"
}

variable "instance_count" {
  description = "Number of data nodes in the managed domain."
  type        = number
  default     = 1
}

variable "dedicated_master_enabled" {
  description = "Enable dedicated master nodes for the managed domain."
  type        = bool
  default     = false
}

variable "dedicated_master_type" {
  description = "Instance type for dedicated master nodes."
  type        = string
  default     = "r6g.large.search"
}

variable "dedicated_master_count" {
  description = "Number of dedicated master nodes."
  type        = number
  default     = 3
}

variable "zone_awareness_enabled" {
  description = "Enable multi-AZ zone awareness for managed domain."
  type        = bool
  default     = false
}

variable "availability_zone_count" {
  description = "Number of AZs for zone-aware managed domain (2 or 3)."
  type        = number
  default     = 2
}

variable "ebs_enabled" {
  description = "Enable EBS volumes for data node storage."
  type        = bool
  default     = true
}

variable "ebs_volume_size_gb" {
  description = "EBS volume size in GB per data node."
  type        = number
  default     = 20
}

variable "ebs_volume_type" {
  description = "EBS volume type: gp3, gp2, io1."
  type        = string
  default     = "gp3"
}

variable "domain_vpc_subnet_ids" {
  description = "Subnet IDs for managed domain VPC deployment."
  type        = list(string)
  default     = []
}

variable "domain_vpc_security_group_ids" {
  description = "Security group IDs for managed domain."
  type        = list(string)
  default     = []
}

variable "domain_access_policy" {
  description = "JSON access policy for the managed domain. Defaults to deny-all (set explicitly)."
  type        = string
  default     = null
}

variable "enable_domain_logging" {
  description = "Enable CloudWatch logging for managed domain (INDEX_SLOW_LOGS, SEARCH_SLOW_LOGS, ES_APPLICATION_LOGS)."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 14
}

variable "enable_encrypt_at_rest" {
  description = "Enable encryption at rest for managed domain."
  type        = bool
  default     = true
}

variable "enable_node_to_node_encryption" {
  description = "Enable node-to-node TLS encryption for managed domain."
  type        = bool
  default     = true
}

variable "enforce_https" {
  description = "Require HTTPS for all traffic to managed domain."
  type        = bool
  default     = true
}

variable "tls_security_policy" {
  description = "TLS security policy for managed domain."
  type        = string
  default     = "Policy-Min-TLS-1-2-2019-07"
}

variable "automated_snapshot_start_hour" {
  description = "UTC hour for automated snapshot of managed domain (0-23)."
  type        = number
  default     = 1
}
