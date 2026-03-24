aws_region  = "us-east-1"
name        = "platform"
environment = "dev"
project     = "platform"
owner       = "network-team"
cost_center = "CC-100"

enable_site_to_site_vpn = true
transit_gateway_id      = "tgw-0abc123dev" # shared lower-env TGW

customer_gateways = {
  "dc-primary" = {
    bgp_asn    = 65000
    ip_address = "203.0.113.10"
  }
}
