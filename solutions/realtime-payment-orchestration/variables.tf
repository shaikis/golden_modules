# ===========================================================================
# GLOBAL
# ===========================================================================
variable "name" {
  description = "Solution name prefix (e.g. 'payments', 'acme-pay')."
  type        = string
  default     = "payments"
}

variable "environment" {
  description = "Deployment environment: dev | staging | prod."
  type        = string
  default     = "prod"
}

variable "project" {
  type    = string
  default = "realtime-payments"
}

variable "owner" {
  type    = string
  default = "payments-platform"
}

variable "cost_center" {
  type    = string
  default = "CC-PAYMENTS"
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ===========================================================================
# REGIONS
# ===========================================================================
variable "primary_region" {
  description = "Primary AWS region (all active traffic)."
  type        = string
  default     = "us-east-1"
}

variable "failover_region" {
  description = "Failover AWS region (standby MSK + DynamoDB replica)."
  type        = string
  default     = "us-west-2"
}

# ===========================================================================
# NETWORK
# ===========================================================================
variable "vpc_cidr" {
  description = "VPC CIDR block for the primary region."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to deploy into (recommend 3 for MSK HA)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnets" {
  description = "Map of AZ → private subnet CIDR (for MSK brokers and Lambda)."
  type        = map(string)
  default = {
    "us-east-1a" = "10.0.1.0/24"
    "us-east-1b" = "10.0.2.0/24"
    "us-east-1c" = "10.0.3.0/24"
  }
}

variable "public_subnets" {
  description = "Map of AZ → public subnet CIDR (for NAT GW)."
  type        = map(string)
  default = {
    "us-east-1a" = "10.0.101.0/24"
    "us-east-1b" = "10.0.102.0/24"
    "us-east-1c" = "10.0.103.0/24"
  }
}

# ===========================================================================
# MSK
# ===========================================================================
variable "msk_instance_type" {
  description = "MSK broker instance type. kafka.m5.large for dev, kafka.m5.4xlarge for prod."
  type        = string
  default     = "kafka.m5.large"
}

variable "msk_broker_count" {
  description = "Number of MSK broker nodes (must be a multiple of AZ count)."
  type        = number
  default     = 3
}

variable "msk_ebs_volume_size" {
  description = "EBS volume size per MSK broker in GB."
  type        = number
  default     = 500
}

variable "msk_kafka_version" {
  description = "Apache Kafka version."
  type        = string
  default     = "3.5.1"
}

variable "failover_msk_cluster_arn" {
  description = "ARN of the standby MSK cluster in the failover region (for MSK Replicator)."
  type        = string
  default     = null
}

variable "failover_msk_subnet_ids" {
  description = "Subnet IDs in the failover region VPC (for MSK Replicator ENIs)."
  type        = list(string)
  default     = []
}

variable "failover_msk_security_group_ids" {
  description = "Security group IDs in the failover region VPC (for MSK Replicator)."
  type        = list(string)
  default     = []
}

# ===========================================================================
# LAMBDA MICROSERVICES
# ===========================================================================
variable "lambda_code_s3_bucket" {
  description = "S3 bucket containing Lambda deployment packages."
  type        = string
}

variable "lambda_memory_mb" {
  description = "Lambda memory in MB for payment microservices (higher = faster + more CPU)."
  type        = number
  default     = 512
}

variable "lambda_timeout_seconds" {
  description = "Lambda timeout in seconds for payment microservices."
  type        = number
  default     = 60
}

variable "lambda_reserved_concurrency" {
  description = "Reserved concurrency per Lambda function (-1 = unreserved)."
  type        = number
  default     = 200
}

variable "lambda_architectures" {
  description = "Lambda instruction set: x86_64 or arm64 (Graviton — recommended for cost savings)."
  type        = list(string)
  default     = ["arm64"]
}

# ===========================================================================
# API
# ===========================================================================
variable "api_domain_name" {
  description = "Custom domain for the payment API (e.g. api.payments.example.com). Leave null to use CloudFront domain."
  type        = string
  default     = null
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (us-east-1) for CloudFront HTTPS. Required when api_domain_name is set."
  type        = string
  default     = null
}

variable "api_throttle_rate_limit" {
  description = "API Gateway per-route rate limit (requests/second)."
  type        = number
  default     = 10000
}

variable "api_throttle_burst_limit" {
  description = "API Gateway per-route burst limit."
  type        = number
  default     = 50000
}

# ===========================================================================
# WAF
# ===========================================================================
variable "waf_rate_limit_per_5min" {
  description = "WAF rate limit per IP per 5 minutes before blocking."
  type        = number
  default     = 10000
}

variable "waf_geo_block_countries" {
  description = "List of ISO country codes to block at WAF (e.g. state-sanctioned countries)."
  type        = list(string)
  default     = ["KP", "IR", "SY", "CU"]  # OFAC sanctioned
}

variable "payment_api_allowed_cidrs" {
  description = "List of trusted CIDR ranges (partner banks, internal) for WAF allow-listing."
  type        = list(string)
  default     = []
}

# ===========================================================================
# OBSERVABILITY
# ===========================================================================
variable "alarm_sns_email" {
  description = "Email address to subscribe to payment alarm SNS topic."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days."
  type        = number
  default     = 365
}
