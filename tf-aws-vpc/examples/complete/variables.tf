variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name for the VPC."
  type        = string
  default     = "platform"
}

variable "name_prefix" {
  description = "Optional prefix prepended to name."
  type        = string
  default     = "prod"
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)."
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Project name."
  type        = string
  default     = "platform"
}

variable "owner" {
  description = "Team or individual owning this resource."
  type        = string
  default     = "infra-team"
}

variable "cost_center" {
  description = "Cost center code."
  type        = string
  default     = "CC-100"
}

variable "tags" {
  description = "Additional tags to merge with defaults."
  type        = map(string)
  default = {
    DataClassification = "Internal"
    Compliance         = "SOC2"
  }
}

variable "cidr_block" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.10.0.0/16"
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
  description = "List of AZs to deploy subnets into."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)."
  type        = list(string)
  default     = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for isolated database subnets (one per AZ)."
  type        = list(string)
  default     = ["10.10.20.0/24", "10.10.21.0/24", "10.10.22.0/24"]
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IPs in public subnets."
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Provision NAT Gateway(s) for private subnets."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway instead of one per AZ."
  type        = bool
  default     = false
}

variable "enable_vpn_gateway" {
  description = "Create a Virtual Private Gateway."
  type        = bool
  default     = false
}

variable "enable_s3_endpoint" {
  description = "Create a Gateway VPC endpoint for S3."
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Create a Gateway VPC endpoint for DynamoDB."
  type        = bool
  default     = true
}

variable "interface_endpoints" {
  description = "Map of Interface VPC endpoints to create."
  type = map(object({
    service_name        = string
    private_dns_enabled = optional(bool, true)
    subnet_ids          = optional(list(string), [])
    security_group_ids  = optional(list(string), [])
  }))
  default = {
    ssm = {
      service_name        = "com.amazonaws.us-east-1.ssm"
      private_dns_enabled = true
    }
    ssmmessages = {
      service_name        = "com.amazonaws.us-east-1.ssmmessages"
      private_dns_enabled = true
    }
    ec2messages = {
      service_name        = "com.amazonaws.us-east-1.ec2messages"
      private_dns_enabled = true
    }
  }
}

variable "enable_flow_log" {
  description = "Enable VPC Flow Logs."
  type        = bool
  default     = true
}

variable "flow_log_destination_type" {
  description = "Destination for flow logs: cloud-watch-logs or s3."
  type        = string
  default     = "cloud-watch-logs"
}

variable "flow_log_traffic_type" {
  description = "Type of traffic to capture: ACCEPT, REJECT, or ALL."
  type        = string
  default     = "ALL"
}

variable "flow_log_retention_days" {
  description = "CloudWatch log retention in days (flow logs)."
  type        = number
  default     = 365
}

variable "kms_name" {
  description = "Name for the KMS key used to encrypt flow logs."
  type        = string
  default     = "vpc-flowlogs"
}
