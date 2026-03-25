variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "myapp"
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

# ── Site-to-Site ───────────────────────────────────────────────────────────
variable "enable_site_to_site_vpn" {
  type    = bool
  default = false
}
variable "transit_gateway_id" {
  type    = string
  default = null
}

variable "customer_gateways" {
  type = map(object({
    bgp_asn                                 = number
    ip_address                              = string
    device_name                             = optional(string, null)
    type                                    = optional(string, "ipsec.1")
    static_routes_only                      = optional(bool, false)
    static_routes                           = optional(list(string), [])
    local_ipv4_network_cidr                 = optional(string, null)
    remote_ipv4_network_cidr                = optional(string, null)
    outside_ip_address_type                 = optional(string, "PublicIpv4")
    transport_transit_gateway_attachment_id = optional(string, null)
    tunnel1_inside_cidr                     = optional(string, null)
    tunnel1_preshared_key                   = optional(string, null)
    tunnel1_ike_versions                    = optional(list(string), ["ikev2"])
    tunnel1_phase1_dh_group_numbers         = optional(list(number), [14, 19, 20])
    tunnel1_phase1_encryption_algorithms    = optional(list(string), ["AES256-GCM-16"])
    tunnel1_phase1_integrity_algorithms     = optional(list(string), ["SHA2-256"])
    tunnel1_phase2_dh_group_numbers         = optional(list(number), [14, 19, 20])
    tunnel1_phase2_encryption_algorithms    = optional(list(string), ["AES256-GCM-16"])
    tunnel1_phase2_integrity_algorithms     = optional(list(string), ["SHA2-256"])
    tunnel1_startup_action                  = optional(string, "start")
    tunnel2_inside_cidr                     = optional(string, null)
    tunnel2_preshared_key                   = optional(string, null)
    tunnel2_ike_versions                    = optional(list(string), ["ikev2"])
    tunnel2_startup_action                  = optional(string, "start")
  }))
  default = {}
}

# ── Client VPN ─────────────────────────────────────────────────────────────
variable "enable_client_vpn" {
  type    = bool
  default = false
}
variable "client_vpn_cidr" {
  type    = string
  default = "10.200.0.0/16"
}
variable "client_vpn_vpc_id" {
  type    = string
  default = null
}
variable "client_vpn_subnet_ids" {
  type    = list(string)
  default = []
}
variable "client_vpn_security_group_ids" {
  type    = list(string)
  default = []
}
variable "client_vpn_server_cert_arn" {
  type    = string
  default = null
}
variable "client_vpn_root_cert_chain_arn" {
  type    = string
  default = null
}
variable "client_vpn_saml_provider_arn" {
  type    = string
  default = null
}
variable "client_vpn_self_service_saml_provider_arn" {
  type    = string
  default = null
}
variable "client_vpn_dns_servers" {
  type    = list(string)
  default = []
}
variable "client_vpn_split_tunnel" {
  type    = bool
  default = true
}
variable "client_vpn_transport_protocol" {
  type    = string
  default = "udp"
}
variable "client_vpn_vpn_port" {
  type    = number
  default = 443
}
variable "client_vpn_session_timeout_hours" {
  type    = number
  default = 12
}
variable "client_vpn_log_retention_days" {
  type    = number
  default = 90
}

variable "client_vpn_authorization_rules" {
  type = map(object({
    target_network_cidr  = string
    access_group_id      = optional(string, null)
    authorize_all_groups = optional(bool, true)
    description          = optional(string, "")
  }))
  default = {}
}

variable "client_vpn_additional_routes" {
  type = map(object({
    destination_cidr     = string
    target_vpc_subnet_id = string
    description          = optional(string, "")
  }))
  default = {}
}
