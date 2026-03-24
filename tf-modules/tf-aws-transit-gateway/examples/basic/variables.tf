variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name for the Transit Gateway."
  type        = string
  default     = "platform-hub"
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)."
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Project name."
  type        = string
  default     = "networking"
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

variable "vpc_attachments" {
  description = "Map of VPC attachments. Key = attachment name."
  type = map(object({
    vpc_id                                          = string
    subnet_ids                                      = list(string)
    dns_support                                     = optional(string, "enable")
    ipv6_support                                    = optional(string, "disable")
    appliance_mode_support                          = optional(string, "disable")
    transit_gateway_default_route_table_association = optional(bool, true)
    transit_gateway_default_route_table_propagation = optional(bool, true)
    route_table_key                                 = optional(string, null)
  }))
  default = {
    shared_services = {
      vpc_id     = "vpc-shared"
      subnet_ids = ["subnet-ss-a", "subnet-ss-b"]
    }
    app_prod = {
      vpc_id     = "vpc-app"
      subnet_ids = ["subnet-app-a", "subnet-app-b"]
    }
    data_prod = {
      vpc_id     = "vpc-data"
      subnet_ids = ["subnet-data-a", "subnet-data-b"]
    }
  }
}
