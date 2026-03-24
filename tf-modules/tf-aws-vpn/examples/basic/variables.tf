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

variable "enable_site_to_site_vpn" {
  type    = bool
  default = true
}
variable "transit_gateway_id" {
  type    = string
  default = null
}

variable "customer_gateways" {
  type = map(object({
    bgp_asn    = number
    ip_address = string
  }))
  default = {}
}
