# =============================================================================
# Complete Example — Variables
# =============================================================================

variable "environment" {
  description = "Deployment environment label (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = "Short prefix prepended to resource names."
  type        = string
  default     = ""
}

# ── Zone configuration ────────────────────────────────────────────────────────

variable "public_zone_name" {
  description = "DNS domain name for the public hosted zone (e.g. 'example.com')."
  type        = string
}

variable "private_zone_name" {
  description = "DNS domain name for the private hosted zone (e.g. 'internal.example.com')."
  type        = string
  default     = "internal.example.com"
}

variable "vpc_id" {
  description = "VPC ID to associate with the private hosted zone."
  type        = string
}

# ── ALB targets ──────────────────────────────────────────────────────────────

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  type        = string
}

variable "alb_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer."
  type        = string
}

variable "secondary_alb_dns_name" {
  description = "DNS name of the secondary ALB (for failover)."
  type        = string
}

variable "secondary_alb_zone_id" {
  description = "Hosted zone ID of the secondary ALB."
  type        = string
}

# ── Resolver networking ───────────────────────────────────────────────────────

variable "resolver_subnet_ids" {
  description = "List of at least 2 subnet IDs (in different AZs) for Resolver endpoints."
  type        = list(string)
  default     = []
}

variable "resolver_security_group_ids" {
  description = "Security group IDs for Resolver endpoints (allow UDP/TCP 53)."
  type        = list(string)
  default     = []
}

variable "on_premises_dns_ips" {
  description = "IP addresses of on-premises DNS servers to forward corp. domain queries to."
  type        = list(string)
  default     = ["192.168.1.53", "192.168.2.53"]
}

# ── DNSSEC ────────────────────────────────────────────────────────────────────

variable "dnssec_kms_key_arn" {
  description = <<-EOT
    ARN of an existing KMS asymmetric key (ECC_NIST_P256, SIGN_VERIFY) in us-east-1.
    Required when enable_dnssec = true.
    Example: "arn:aws:kms:us-east-1:123456789012:key/mrk-12345678"
  EOT
  type        = string
  default     = null
}

variable "enable_dnssec" {
  description = "Set to true to enable DNSSEC on the public zone (requires dnssec_kms_key_arn)."
  type        = bool
  default     = false
}

# ── CIDR routing ─────────────────────────────────────────────────────────────

variable "enable_cidr_routing" {
  description = "Set to true to create a CIDR collection for IP-based routing."
  type        = bool
  default     = false
}

# ── CloudWatch alarm health check ────────────────────────────────────────────

variable "rds_cloudwatch_alarm_name" {
  description = "Name of the CloudWatch alarm monitoring RDS health (for private health check)."
  type        = string
  default     = "prod-rds-primary-health"
}

# ── Tags ──────────────────────────────────────────────────────────────────────

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
