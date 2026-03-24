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
  default = {
} }

# ===========================================================================
# ENI DEFINITIONS
# ===========================================================================
variable "network_interfaces" {
  description = "Map of ENI logical name → config."
  type = map(object({
    subnet_id               = string
    security_group_ids      = optional(list(string), [])
    private_ips             = optional(list(string), [])        # static IPs; [] = DHCP
    private_ip_list_enabled = optional(bool, false)
    ipv4_prefix_count       = optional(number, null)
    source_dest_check       = optional(bool, true)              # false for NVAs/NATs
    description             = optional(string, "")
    attachment = optional(object({
      instance_id  = string
      device_index = number                                     # 0=eth0, 1=eth1, …
    }), null)
    eip = optional(object({
      domain                    = optional(string, "vpc")
      associate_with_private_ip = optional(string, null)
    }), null)
    additional_tags = optional(map(string), {})
  }))
  default = {}
}
