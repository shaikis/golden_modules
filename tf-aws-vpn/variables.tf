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
  type = map(string)
  default = {
  }
}

# ===========================================================================
# SITE-TO-SITE VPN
# ===========================================================================
variable "enable_site_to_site_vpn" {
  description = "Create Site-to-Site VPN connections."
  type        = bool
  default     = false
}

# Gateway side: attach to VGW or TGW
variable "transit_gateway_id" {
  description = "Attach VPN to an existing Transit Gateway."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID for Virtual Private Gateway (used when NOT using TGW)."
  type        = string
  default     = null
}

variable "create_vpn_gateway" {
  description = "Create a Virtual Private Gateway (needed when not using TGW)."
  type        = bool
  default     = false
}

variable "vpn_gateway_amazon_side_asn" {
  type    = number
  default = 64512
}

variable "propagating_vgw_route_tables" {
  description = "Route table IDs to propagate VGW routes into."
  type        = list(string)
  default     = []
}

# Customer Gateways + VPN Connections
variable "customer_gateways" {
  description = "Map of customer gateways and their VPN connections."
  type = map(object({
    bgp_asn         = number
    ip_address      = string
    device_name     = optional(string, null)
    certificate_arn = optional(string, null)

    # VPN connection settings
    type                                    = optional(string, "ipsec.1")
    static_routes_only                      = optional(bool, false)
    local_ipv4_network_cidr                 = optional(string, null)
    remote_ipv4_network_cidr                = optional(string, null)
    outside_ip_address_type                 = optional(string, "PublicIpv4")
    transport_transit_gateway_attachment_id = optional(string, null)

    # Static routes (when static_routes_only = true)
    static_routes = optional(list(string), [])

    # Tunnel options
    tunnel1_inside_cidr                  = optional(string, null)
    tunnel1_preshared_key                = optional(string, null)
    tunnel1_ike_versions                 = optional(list(string), ["ikev2"])
    tunnel1_phase1_dh_group_numbers      = optional(list(number), [14, 19, 20])
    tunnel1_phase1_encryption_algorithms = optional(list(string), ["AES256-GCM-16"])
    tunnel1_phase1_integrity_algorithms  = optional(list(string), ["SHA2-256"])
    tunnel1_phase2_dh_group_numbers      = optional(list(number), [14, 19, 20])
    tunnel1_phase2_encryption_algorithms = optional(list(string), ["AES256-GCM-16"])
    tunnel1_phase2_integrity_algorithms  = optional(list(string), ["SHA2-256"])
    tunnel1_startup_action               = optional(string, "start")

    tunnel2_inside_cidr    = optional(string, null)
    tunnel2_preshared_key  = optional(string, null)
    tunnel2_ike_versions   = optional(list(string), ["ikev2"])
    tunnel2_startup_action = optional(string, "start")
  }))
  default = {}
}

# ===========================================================================
# CLIENT VPN
# ===========================================================================
variable "enable_client_vpn" {
  description = "Create an AWS Client VPN endpoint."
  type        = bool
  default     = false
}

variable "client_vpn_cidr" {
  description = "CIDR for VPN client IP pool. Must be /12–/22."
  type        = string
  default     = "10.200.0.0/16"
}

variable "client_vpn_vpc_id" {
  description = "VPC to associate the Client VPN endpoint with."
  type        = string
  default     = null
}

variable "client_vpn_subnet_ids" {
  description = "Subnets to associate for VPN access."
  type        = list(string)
  default     = []
}

variable "client_vpn_server_cert_arn" {
  description = "ACM certificate ARN for the VPN server (required)."
  type        = string
  default     = null
}

variable "client_vpn_root_cert_chain_arn" {
  description = "ACM cert chain ARN for mutual TLS client auth."
  type        = string
  default     = null
}

variable "client_vpn_saml_provider_arn" {
  description = "SAML provider ARN for federated authentication."
  type        = string
  default     = null
}

variable "client_vpn_self_service_saml_provider_arn" {
  description = "Self-service SAML provider ARN."
  type        = string
  default     = null
}

variable "client_vpn_dns_servers" {
  description = "DNS servers for VPN clients."
  type        = list(string)
  default     = []
}

variable "client_vpn_split_tunnel" {
  description = "Enable split-tunnel (only route VPC traffic via VPN)."
  type        = bool
  default     = true
}

variable "client_vpn_transport_protocol" {
  description = "udp or tcp."
  type        = string
  default     = "udp"
}

variable "client_vpn_vpn_port" {
  description = "443 or 1194."
  type        = number
  default     = 443
}

variable "client_vpn_session_timeout_hours" {
  description = "Maximum VPN session duration in hours."
  type        = number
  default     = 12
}

variable "client_vpn_security_group_ids" {
  description = "Security group IDs for the Client VPN endpoint."
  type        = list(string)
  default     = []
}

variable "client_vpn_authorization_rules" {
  description = "Authorization rules for Client VPN."
  type = map(object({
    target_network_cidr  = string
    access_group_id      = optional(string, null)
    authorize_all_groups = optional(bool, true)
    description          = optional(string, "")
  }))
  default = {
    all_vpc = {
      target_network_cidr  = "10.0.0.0/8"
      authorize_all_groups = true
    }
  }
}

variable "client_vpn_additional_routes" {
  description = "Additional routes for client VPN (destination → subnet)."
  type = map(object({
    destination_cidr     = string
    target_vpc_subnet_id = string
    description          = optional(string, "")
  }))
  default = {}
}

variable "client_vpn_cloudwatch_log_group" {
  description = "CloudWatch log group for connection logs."
  type        = string
  default     = null
}

variable "client_vpn_log_retention_days" {
  type    = number
  default = 90
}
