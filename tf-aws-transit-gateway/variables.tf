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

# ---------------------------------------------------------------------------
# Transit Gateway
# ---------------------------------------------------------------------------
variable "amazon_side_asn" {
  description = "Private ASN for the Amazon side of TGW (64512-65534, 4200000000-4294967294)."
  type        = number
  default     = 64512
}

variable "description" {
  description = "Optional description for the Transit Gateway."
  type        = string
  default     = null
}

variable "auto_accept_shared_attachments" {
  type    = string
  default = "disable"
}
variable "default_route_table_association" {
  type    = string
  default = "enable"
}
variable "default_route_table_propagation" {
  type    = string
  default = "enable"
}
variable "dns_support" {
  type    = string
  default = "enable"
}
variable "vpn_ecmp_support" {
  type    = string
  default = "enable"
}
variable "multicast_support" {
  type    = string
  default = "disable"
}

variable "security_group_referencing_support" {
  description = "Enable or disable security group referencing support on the Transit Gateway."
  type        = string
  default     = null
}

variable "transit_gateway_cidr_blocks" {
  type    = list(string)
  default = []
}

# ---------------------------------------------------------------------------
# VPC Attachments
# ---------------------------------------------------------------------------
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
    association_route_table_key                     = optional(string, null)   # key into tgw_route_tables
    propagation_route_table_keys                    = optional(list(string), [])
    route_table_key                                 = optional(string, null)   # backward-compatible fallback
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Route Tables
# ---------------------------------------------------------------------------
variable "tgw_route_tables" {
  description = "Custom TGW route tables. Key = route table name."
  type = map(object({
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "tgw_routes" {
  description = "Static routes in TGW route tables."
  type = map(object({
    route_table_key               = string
    destination_cidr              = string
    attachment_key                = optional(string, null) # key into vpc_attachments
    transit_gateway_attachment_id = optional(string, null) # direct attachment ID for VPN/DX/other attachments
    blackhole                     = optional(bool, false)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# VPN Attachments (from on-premises)
# ---------------------------------------------------------------------------
variable "vpn_attachments" {
  description = "Map of VPN connections to attach to TGW. Requires aws_vpn_connection resources pre-created."
  type = map(object({
    vpn_connection_id = string
    route_table_key   = optional(string, null)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Direct Connect Gateway Attachment
# ---------------------------------------------------------------------------
variable "dx_gateway_attachments" {
  description = "Map of Direct Connect Gateway attachments. If dx_gateway_owner_account_id is set, creates a cross-account association proposal; otherwise creates a same-account association."
  type = map(object({
    dx_gateway_id               = string
    dx_gateway_owner_account_id = optional(string, null)
    allowed_prefixes            = optional(list(string), [])
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# RAM Resource Sharing (share TGW with other accounts)
# ---------------------------------------------------------------------------
variable "ram_share_enabled" {
  description = "Share TGW via AWS RAM."
  type        = bool
  default     = false
}

variable "ram_allow_external_principals" {
  type    = bool
  default = false
}

variable "ram_principals" {
  description = "List of AWS account IDs or OU ARNs to share with."
  type        = list(string)
  default     = []
}
