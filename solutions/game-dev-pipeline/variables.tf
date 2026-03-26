# =============================================================================
# Game Development Pipeline — Variables
# Perforce P4 + Unreal Engine Horde on AWS
# =============================================================================

# ---------------------------------------------------------------------------
# Naming & Tagging
# ---------------------------------------------------------------------------
variable "name" {
  description = "Base name for all resources, e.g. 'anycompany-games'."
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
# Domain
# ---------------------------------------------------------------------------
variable "domain_name" {
  description = "Base domain name, e.g. 'games.example.com'. Used for Route 53 records and ACM wildcard certificate."
  type        = string
}

variable "route53_zone_id" {
  description = "Existing Route 53 hosted zone ID for the domain. Obtain with: aws route53 list-hosted-zones."
  type        = string
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones to deploy subnets into. Must match the region set in aws_region."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# ---------------------------------------------------------------------------
# Perforce P4
# ---------------------------------------------------------------------------
variable "p4_instance_type" {
  description = "EC2 instance type for the P4 Commit Server. c5.2xlarge balances CPU and network for version control workloads handling large binary assets."
  type        = string
  default     = "c5.2xlarge"
}

variable "p4_data_volume_size_gb" {
  description = "EBS volume size in GB for the P4 depot data directory. Plan for 3x your current depot size to allow for growth and versioned content."
  type        = number
  default     = 500
}

variable "p4_data_volume_type" {
  description = "EBS volume type for P4 depot. gp3 provides predictable IOPS and throughput."
  type        = string
  default     = "gp3"
}

variable "p4_data_volume_iops" {
  description = "Provisioned IOPS for the P4 data volume (gp3 baseline is 3000, max 16000)."
  type        = number
  default     = 3000
}

variable "p4_admin_email" {
  description = "Email address for the Perforce admin user account."
  type        = string
}

# ---------------------------------------------------------------------------
# Unreal Engine Horde
# ---------------------------------------------------------------------------
variable "horde_instance_type" {
  description = "ECS task or EC2 instance type for the Horde Controller service."
  type        = string
  default     = "c5.2xlarge"
}

variable "horde_agent_instance_type" {
  description = "EC2 instance type for Horde build agents. c5.4xlarge provides 16 vCPUs and 32 GB RAM for parallel Unreal Engine compilation."
  type        = string
  default     = "c5.4xlarge"
}

variable "horde_agent_min_size" {
  description = "Minimum number of Horde build agent instances."
  type        = number
  default     = 1
}

variable "horde_agent_max_size" {
  description = "Maximum number of Horde build agent instances the ASG can scale to."
  type        = number
  default     = 10
}

variable "horde_agent_desired" {
  description = "Desired number of Horde build agent instances at steady state."
  type        = number
  default     = 2
}

variable "horde_use_spot" {
  description = "Use EC2 Spot Instances for Horde build agents. Reduces build agent costs by up to 90% versus On-Demand pricing."
  type        = bool
  default     = true
}

variable "horde_spot_max_price" {
  description = "Maximum Spot price per hour for Horde build agents. Null caps at the On-Demand price, which is the recommended setting."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# DocumentDB (Horde database — MongoDB-compatible)
# ---------------------------------------------------------------------------
variable "docdb_instance_class" {
  description = "DocumentDB instance class for Horde's job and agent metadata store."
  type        = string
  default     = "db.r6g.large"
}

variable "docdb_cluster_size" {
  description = "Number of DocumentDB instances (1 primary + readers). Use 1 for dev/test, 3 for production HA."
  type        = number
  default     = 3
}

# ---------------------------------------------------------------------------
# ElastiCache Redis (Horde cache)
# ---------------------------------------------------------------------------
variable "redis_node_type" {
  description = "ElastiCache node type for Redis. Horde uses Redis for session caching and job queuing."
  type        = string
  default     = "cache.r6g.large"
}

variable "redis_num_cache_nodes" {
  description = "Number of Redis cache nodes (primary + replicas). Minimum 2 for Multi-AZ failover."
  type        = number
  default     = 2
}

# ---------------------------------------------------------------------------
# Security
# ---------------------------------------------------------------------------
variable "enable_kms" {
  description = "Create a customer-managed KMS key to encrypt EBS volumes, S3 buckets, DocumentDB, and Secrets Manager."
  type        = bool
  default     = true
}

variable "p4_allowed_cidrs" {
  description = "CIDR ranges allowed to reach the Perforce server on TCP/1666. Restrict to your studio office IPs in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "horde_allowed_cidrs" {
  description = "CIDR ranges allowed to access the Horde web UI via the ALB on HTTPS/443. Restrict to studio network in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
