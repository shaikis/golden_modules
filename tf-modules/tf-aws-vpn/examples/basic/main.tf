provider "aws" { region = var.aws_region }

module "vpn" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  # Site-to-Site via Transit Gateway
  enable_site_to_site_vpn = var.enable_site_to_site_vpn
  transit_gateway_id      = var.transit_gateway_id

  customer_gateways = var.customer_gateways
}

output "vpn_connection_ids" { value = module.vpn.vpn_connection_ids }
output "vpn_connection_tunnel1_addresses" { value = module.vpn.vpn_connection_tunnel1_addresses }
