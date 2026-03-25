variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name for the security group."
  type        = string
  default     = "web-app"
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

variable "vpc_id" {
  description = "ID of the VPC to create the security group in."
  type        = string
  default     = "vpc-0123456789abcdef0"
}

variable "ingress_rules" {
  description = "Map of ingress rules. Key = rule name."
  type = map(object({
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    source_sg_ids    = optional(list(string), [])
    self             = optional(bool, false)
    description      = optional(string, "")
  }))
  default = {
    http = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "HTTP from internal"
    }
    https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "HTTPS from internal"
    }
  }
}
