variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name for the Transit Gateway."
  type        = string
  default     = "enterprise-hub"
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
  default     = "network-core"
}

variable "owner" {
  description = "Team or individual owning this resource."
  type        = string
  default     = "network-team"
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

variable "amazon_side_asn" {
  description = "Private ASN for the Amazon side of TGW."
  type        = number
  default     = 65000
}

variable "vpn_ecmp_support" {
  description = "Enable VPN ECMP support."
  type        = string
  default     = "enable"
}

variable "default_route_table_association" {
  description = "Whether to associate attachments with the default route table."
  type        = string
  default     = "disable"
}

variable "default_route_table_propagation" {
  description = "Whether to propagate routes to the default route table."
  type        = string
  default     = "disable"
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
      vpc_id          = "vpc-shared"
      subnet_ids      = ["subnet-ss-a", "subnet-ss-b", "subnet-ss-c"]
      route_table_key = "shared"
    }
    prod_app = {
      vpc_id          = "vpc-app"
      subnet_ids      = ["subnet-app-a", "subnet-app-b", "subnet-app-c"]
      route_table_key = "workloads"
    }
    prod_data = {
      vpc_id          = "vpc-data"
      subnet_ids      = ["subnet-data-a", "subnet-data-b", "subnet-data-c"]
      route_table_key = "workloads"
    }
  }
}

variable "tgw_route_tables" {
  description = "Custom TGW route tables. Key = route table name."
  type = map(object({
    tags = optional(map(string), {})
  }))
  default = {
    shared    = {}
    workloads = {}
    onprem    = {}
  }
}

variable "tgw_routes" {
  description = "Static routes in TGW route tables."
  type = map(object({
    route_table_key  = string
    destination_cidr = string
    attachment_key   = optional(string, null)
    blackhole        = optional(bool, false)
  }))
  default = {
    default_to_shared = {
      route_table_key  = "workloads"
      destination_cidr = "0.0.0.0/0"
      attachment_key   = "shared_services"
    }
    onprem_to_all = {
      route_table_key  = "onprem"
      destination_cidr = "10.0.0.0/8"
      attachment_key   = "shared_services"
    }
  }
}

variable "ram_share_enabled" {
  description = "Share TGW via AWS RAM."
  type        = bool
  default     = true
}

variable "ram_allow_external_principals" {
  description = "Allow external principals in the RAM share."
  type        = bool
  default     = false
}

variable "ram_principals" {
  description = "List of AWS account IDs or OU ARNs to share with."
  type        = list(string)
  default = [
    "arn:aws:organizations::123456789:ou/o-example/ou-xxxx-yyyyyyyy",
  ]
}
