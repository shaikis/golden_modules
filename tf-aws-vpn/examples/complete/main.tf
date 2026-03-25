provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name        = "${var.name}-vpn"
  environment = var.environment
}

module "vpn" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  # ── Site-to-Site ─────────────────────────────────────────────
  enable_site_to_site_vpn = var.enable_site_to_site_vpn
  transit_gateway_id      = var.transit_gateway_id
  customer_gateways       = var.customer_gateways

  # ── Client VPN ───────────────────────────────────────────────
  enable_client_vpn                         = var.enable_client_vpn
  client_vpn_cidr                           = var.client_vpn_cidr
  client_vpn_vpc_id                         = var.client_vpn_vpc_id
  client_vpn_subnet_ids                     = var.client_vpn_subnet_ids
  client_vpn_security_group_ids             = var.client_vpn_security_group_ids
  client_vpn_server_cert_arn                = var.client_vpn_server_cert_arn
  client_vpn_root_cert_chain_arn            = var.client_vpn_root_cert_chain_arn
  client_vpn_saml_provider_arn              = var.client_vpn_saml_provider_arn
  client_vpn_self_service_saml_provider_arn = var.client_vpn_self_service_saml_provider_arn
  client_vpn_dns_servers                    = var.client_vpn_dns_servers
  client_vpn_split_tunnel                   = var.client_vpn_split_tunnel
  client_vpn_transport_protocol             = var.client_vpn_transport_protocol
  client_vpn_vpn_port                       = var.client_vpn_vpn_port
  client_vpn_session_timeout_hours          = var.client_vpn_session_timeout_hours
  client_vpn_authorization_rules            = var.client_vpn_authorization_rules
  client_vpn_additional_routes              = var.client_vpn_additional_routes
  client_vpn_log_retention_days             = var.client_vpn_log_retention_days
}

output "vpn_connection_ids" { value = module.vpn.vpn_connection_ids }
output "vpn_connection_tunnel1_addresses" { value = module.vpn.vpn_connection_tunnel1_addresses }
output "client_vpn_endpoint_id" { value = module.vpn.client_vpn_endpoint_id }
output "client_vpn_dns_name" { value = module.vpn.client_vpn_dns_name }
