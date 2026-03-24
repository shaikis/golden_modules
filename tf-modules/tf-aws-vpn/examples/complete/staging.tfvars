# staging uses the SAME VPC/TGW as dev — only env label changes
aws_region  = "us-east-1"
name        = "platform"
environment = "staging"
project     = "platform"
owner       = "network-team"
cost_center = "CC-100"

enable_site_to_site_vpn = true
transit_gateway_id      = "tgw-0abc123shared" # same shared TGW as dev

customer_gateways = {
  "dc-primary" = {
    bgp_asn    = 65000
    ip_address = "203.0.113.10"
  }
}

enable_client_vpn                = true
client_vpn_cidr                  = "10.201.0.0/16"
client_vpn_vpc_id                = "vpc-0devshared" # same lower-env VPC
client_vpn_subnet_ids            = ["subnet-0aaa", "subnet-0bbb"]
client_vpn_security_group_ids    = ["sg-0vpn"]
client_vpn_server_cert_arn       = "arn:aws:acm:us-east-1:111122223333:certificate/staging-server"
client_vpn_root_cert_chain_arn   = "arn:aws:acm:us-east-1:111122223333:certificate/staging-root"
client_vpn_split_tunnel          = true
client_vpn_dns_servers           = ["10.0.0.2"]
client_vpn_session_timeout_hours = 8
client_vpn_log_retention_days    = 30

client_vpn_authorization_rules = {
  all_vpc = {
    target_network_cidr  = "10.0.0.0/8"
    authorize_all_groups = true
    description          = "Allow all VPN users access to shared VPC"
  }
}
