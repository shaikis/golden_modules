# prod has its own dedicated VPC, TGW, and dual CGWs for HA
aws_region  = "us-east-1"
name        = "platform"
environment = "prod"
project     = "platform"
owner       = "network-team"
cost_center = "CC-100"

# ── Site-to-Site ──────────────────────────────────────────────────────────
enable_site_to_site_vpn = true
transit_gateway_id      = "tgw-0xyz789prod" # dedicated prod TGW

customer_gateways = {
  "dc-primary" = {
    bgp_asn                              = 65000
    ip_address                           = "203.0.113.10"
    static_routes_only                   = false
    tunnel1_inside_cidr                  = "169.254.10.0/30"
    tunnel2_inside_cidr                  = "169.254.10.4/30"
    tunnel1_ike_versions                 = ["ikev2"]
    tunnel2_ike_versions                 = ["ikev2"]
    tunnel1_phase1_encryption_algorithms = ["AES256-GCM-16"]
    tunnel1_phase2_encryption_algorithms = ["AES256-GCM-16"]
  }
  "dc-secondary" = {
    bgp_asn    = 65000
    ip_address = "203.0.113.20"
  }
}

# ── Client VPN (SAML/SSO for prod) ────────────────────────────────────────
enable_client_vpn                         = true
client_vpn_cidr                           = "10.210.0.0/16"
client_vpn_vpc_id                         = "vpc-0prodonly" # dedicated prod VPC
client_vpn_subnet_ids                     = ["subnet-0prod1", "subnet-0prod2"]
client_vpn_security_group_ids             = ["sg-0vpnprod"]
client_vpn_server_cert_arn                = "arn:aws:acm:us-east-1:111122223333:certificate/prod-server"
client_vpn_saml_provider_arn              = "arn:aws:iam::111122223333:saml-provider/AWSSSO"
client_vpn_self_service_saml_provider_arn = "arn:aws:iam::111122223333:saml-provider/AWSSSOSelfService"
client_vpn_split_tunnel                   = true
client_vpn_dns_servers                    = ["10.10.0.2"]
client_vpn_session_timeout_hours          = 8
client_vpn_log_retention_days             = 90

client_vpn_authorization_rules = {
  engineers = {
    target_network_cidr  = "10.10.0.0/16"
    access_group_id      = "engineers-group-id"
    authorize_all_groups = false
    description          = "Engineers access to prod VPC"
  }
  ops = {
    target_network_cidr  = "10.10.0.0/16"
    access_group_id      = "ops-group-id"
    authorize_all_groups = false
    description          = "Ops access to prod VPC"
  }
}
