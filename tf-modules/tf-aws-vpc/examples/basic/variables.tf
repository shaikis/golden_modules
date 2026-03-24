variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name for the VPC."
  type        = string
  default     = "my-vpc"
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)."
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name."
  type        = string
  default     = "demo"
}

variable "owner" {
  description = "Team or individual owning this resource."
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center code."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to merge with defaults."
  type        = map(string)
  default     = {}
}

variable "cidr_block" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to deploy subnets into."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Provision NAT Gateway(s) for private subnets."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway instead of one per AZ."
  type        = bool
  default     = true
}
