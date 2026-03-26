# ---------------------------------------------------------------------------
# Naming & Tagging
# ---------------------------------------------------------------------------

variable "name" {
  description = "Base name used for all resources in this solution."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy the solution into."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Additional tags merged onto every resource created by this solution."
  type        = map(string)
  default     = {}
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
  description = "List of Availability Zones to deploy subnets into."
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
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["m5.xlarge"]
}

variable "node_min_size" {
  description = "Minimum number of nodes in the managed node group."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes in the managed node group."
  type        = number
  default     = 10
}

variable "node_desired_size" {
  description = "Desired number of nodes in the managed node group."
  type        = number
  default     = 3
}

variable "enable_adot_addon" {
  description = "Install AWS Distro for OpenTelemetry (ADOT) EKS add-on for metrics and traces collection."
  type        = bool
  default     = true
}

variable "enable_xray_addon" {
  description = "Install AWS X-Ray daemon EKS add-on for distributed tracing."
  type        = bool
  default     = true
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for EKS pod/node metrics."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# AMP (Amazon Managed Prometheus)
# ---------------------------------------------------------------------------

variable "enable_managed_scraper" {
  description = "Create AMP managed scraper that auto-pulls metrics from EKS — no Prometheus sidecar needed."
  type        = bool
  default     = true
}

variable "enable_alert_manager" {
  description = "Enable the AMP Alert Manager."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Observability
# ---------------------------------------------------------------------------

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications. No SNS topic is created when null."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}

# ---------------------------------------------------------------------------
# AWS DevOps Agent
# ---------------------------------------------------------------------------

variable "enable_devops_agent" {
  description = "Provision AWS DevOps Agent Space via CloudFormation Custom Resource."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Security
# ---------------------------------------------------------------------------

variable "enable_kms" {
  description = "Create a customer-managed KMS key to encrypt EKS, AMP, S3, and CloudWatch resources."
  type        = bool
  default     = true
}
