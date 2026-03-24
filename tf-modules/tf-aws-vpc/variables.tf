# ---------------------------------------------------------------------------
# Naming & Tagging
# ---------------------------------------------------------------------------
variable "name" {
  description = "Base name used for all VPC resources."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix prepended to name."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)."
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name."
  type        = string
  default     = ""
}

variable "owner" {
  description = "Team or individual owning this VPC."
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center code."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags merged with defaults."
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets."
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets."
  type        = map(string)
  default     = {}
}

variable "database_subnet_tags" {
  description = "Additional tags for database subnets."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
variable "cidr_block" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_ipv6" {
  description = "Requests an Amazon-provided IPv6 CIDR block."
  type        = bool
  default     = false
}

variable "instance_tenancy" {
  description = "Tenancy option: default or dedicated."
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated"], var.instance_tenancy)
    error_message = "instance_tenancy must be 'default' or 'dedicated'."
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "availability_zones" {
  description = "List of AZs to deploy subnets into (e.g. [\"us-east-1a\", \"us-east-1b\"])."
  type        = list(string)
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)."
  type        = list(string)
  default     = []
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for isolated database subnets (one per AZ)."
  type        = list(string)
  default     = []
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IPs in public subnets."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# NAT Gateway
# ---------------------------------------------------------------------------
variable "enable_nat_gateway" {
  description = "Provision NAT Gateway(s) for private subnets."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway instead of one per AZ (cheaper, less HA)."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------------------------
variable "create_igw" {
  description = "Create an Internet Gateway for the public subnets."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# VPN Gateway
# ---------------------------------------------------------------------------
variable "enable_vpn_gateway" {
  description = "Create a Virtual Private Gateway."
  type        = bool
  default     = false
}

variable "vpn_gateway_amazon_side_asn" {
  description = "ASN for the Amazon side of VPN BGP sessions."
  type        = number
  default     = 64512
}

# ---------------------------------------------------------------------------
# VPC Flow Logs
# ---------------------------------------------------------------------------
variable "enable_flow_log" {
  description = "Enable VPC Flow Logs."
  type        = bool
  default     = true
}

variable "flow_log_destination_type" {
  description = "Destination for flow logs: cloud-watch-logs or s3."
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_log_destination_type)
    error_message = "flow_log_destination_type must be cloud-watch-logs or s3."
  }
}

variable "flow_log_destination_arn" {
  description = "ARN of CloudWatch log group or S3 bucket for flow logs."
  type        = string
  default     = ""
}

variable "flow_log_traffic_type" {
  description = "Type of traffic to capture: ACCEPT, REJECT, or ALL."
  type        = string
  default     = "ALL"
}

variable "flow_log_retention_days" {
  description = "CloudWatch log retention in days (flow logs)."
  type        = number
  default     = 90
}

variable "flow_log_kms_key_id" {
  description = "KMS key ARN for encrypting flow log CloudWatch log group."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# VPC Endpoints
# ---------------------------------------------------------------------------
variable "enable_s3_endpoint" {
  description = "Create a Gateway VPC endpoint for S3."
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Create a Gateway VPC endpoint for DynamoDB."
  type        = bool
  default     = false
}

variable "interface_endpoints" {
  description = "Map of Interface VPC endpoints to create. Key = service short name (e.g. ssm, ec2, secretsmanager)."
  type = map(object({
    service_name        = string # full service name e.g. com.amazonaws.us-east-1.ssm
    private_dns_enabled = optional(bool, true)
    subnet_ids          = optional(list(string), []) # defaults to private subnets
    security_group_ids  = optional(list(string), [])
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# DHCP Options
# ---------------------------------------------------------------------------
variable "enable_dhcp_options" {
  description = "Enable custom DHCP options set."
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Domain name for DHCP options."
  type        = string
  default     = ""
}

variable "dhcp_options_domain_name_servers" {
  description = "DNS servers for DHCP options."
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  description = "NTP servers for DHCP options."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Network ACLs
# ---------------------------------------------------------------------------
variable "create_default_nacl_rules" {
  description = "Create default deny-all NACL overriding AWS permissive default."
  type        = bool
  default     = false
}
