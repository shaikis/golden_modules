# ---------------------------------------------------------------------------
# Naming & Tagging
# ---------------------------------------------------------------------------
variable "name" {
  description = "Base name for all resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Additional tags merged onto all resources."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to deploy subnets into."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# ---------------------------------------------------------------------------
# EKS
# ---------------------------------------------------------------------------
variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.30"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS managed node groups."
  type        = list(string)
  default     = ["m5.xlarge"]
}

variable "node_min_size" {
  description = "Minimum number of nodes in the node group."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes in the node group."
  type        = number
  default     = 8
}

variable "node_desired_size" {
  description = "Desired number of nodes in the node group."
  type        = number
  default     = 3
}

# ---------------------------------------------------------------------------
# Kinesis
# ---------------------------------------------------------------------------
variable "kinesis_shard_count" {
  description = "Number of Kinesis shards. Each shard handles 1MB/s ingest from Fluent Bit."
  type        = number
  default     = 2
}

variable "kinesis_retention_hours" {
  description = "Number of hours Kinesis retains records."
  type        = number
  default     = 24
}

# ---------------------------------------------------------------------------
# OpenSearch
# ---------------------------------------------------------------------------
variable "opensearch_standby_replicas" {
  description = "ENABLED for production (multi-AZ), DISABLED for dev/test to reduce cost."
  type        = string
  default     = "ENABLED"
}

# ---------------------------------------------------------------------------
# Bedrock
# ---------------------------------------------------------------------------
variable "embedding_model_id" {
  description = "Bedrock model used to generate 1024-dimensional vector embeddings from telemetry."
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "llm_model_id" {
  description = "Bedrock LLM for root cause analysis and kubectl command generation."
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "enable_bedrock_guardrail" {
  description = "Enable Bedrock guardrail for prompt injection protection on the chatbot Lambda."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Lambda
# ---------------------------------------------------------------------------
variable "embedding_lambda_memory_mb" {
  description = "Memory in MB for the embedding Lambda function."
  type        = number
  default     = 512
}

variable "chatbot_lambda_memory_mb" {
  description = "Memory in MB for the chatbot Lambda function."
  type        = number
  default     = 1024
}

variable "embedding_lambda_timeout" {
  description = "Timeout in seconds for the embedding Lambda."
  type        = number
  default     = 300
}

variable "chatbot_lambda_timeout" {
  description = "Timeout in seconds for the chatbot Lambda."
  type        = number
  default     = 300
}

variable "kinesis_batch_size" {
  description = "Records per Lambda invocation from Kinesis. Higher = more efficient embedding batching."
  type        = number
  default     = 100
}

# ---------------------------------------------------------------------------
# Observability
# ---------------------------------------------------------------------------
variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications. Null disables email subscription."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}

# ---------------------------------------------------------------------------
# OpenSearch Index
# ---------------------------------------------------------------------------
variable "telemetry_index_name" {
  description = "OpenSearch index name where telemetry embeddings are stored."
  type        = string
  default     = "eks-telemetry"
}

variable "vector_dimensions" {
  description = "Embedding vector dimensions. Must match the embedding model (Titan Embed v2 = 1024)."
  type        = number
  default     = 1024
}

# ---------------------------------------------------------------------------
# Security
# ---------------------------------------------------------------------------
variable "enable_kms" {
  description = "Enable KMS encryption for Kinesis, OpenSearch, S3, and Lambda environment variables."
  type        = bool
  default     = true
}
