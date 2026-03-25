variable "name" {
  type = string
}
variable "name_prefix" {
  type    = string
  default = ""
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "project" {
  type    = string
  default = ""
}
variable "owner" {
  type    = string
  default = ""
}
variable "cost_center" {
  type    = string
  default = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  description = "VPC to create endpoints in."
  type        = string
}

# ===========================================================================
# ENDPOINTS
# ===========================================================================
variable "endpoints" {
  description = <<-EOT
    Map of endpoint key → config.
    service_name: full com.amazonaws.<region>.<service> OR just the service shorthand
                  (e.g. "s3", "ec2", "ssm") — module prepends the region prefix.
    vpc_endpoint_type: Gateway | Interface
  EOT
  type = map(object({
    service_name       = string
    vpc_endpoint_type  = optional(string, "Interface")
    subnet_ids         = optional(list(string), [])
    security_group_ids = optional(list(string), [])
    route_table_ids    = optional(list(string), []) # for Gateway type
    private_dns        = optional(bool, true)
    policy             = optional(string, null)
    ip_address_type    = optional(string, null) # ipv4 | ipv6 | dualstack
  }))
  default = {}
}

# ===========================================================================
# DEFAULTS (applied to all interface endpoints unless overridden per endpoint)
# ===========================================================================
variable "default_subnet_ids" {
  description = "Default subnets for interface endpoints."
  type        = list(string)
  default     = []
}

variable "default_security_group_ids" {
  description = "Default security groups for interface endpoints."
  type        = list(string)
  default     = []
}

variable "default_route_table_ids" {
  description = "Default route table IDs for Gateway endpoints."
  type        = list(string)
  default     = []
}
