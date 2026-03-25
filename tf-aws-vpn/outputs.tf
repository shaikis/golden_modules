# ===========================================================================
# SITE-TO-SITE VPN OUTPUTS
# ===========================================================================
output "vpn_gateway_id" {
  description = "Virtual Private Gateway ID."
  value       = try(aws_vpn_gateway.this[0].id, null)
}

output "customer_gateway_ids" {
  description = "Map of customer gateway key → ID."
  value       = { for k, v in aws_customer_gateway.this : k => v.id }
}

output "vpn_connection_ids" {
  description = "Map of VPN connection key → ID."
  value       = { for k, v in aws_vpn_connection.this : k => v.id }
}

output "vpn_connection_tunnel1_addresses" {
  description = "Map of VPN connection key → Tunnel 1 outside IP."
  value       = { for k, v in aws_vpn_connection.this : k => v.tunnel1_address }
}

output "vpn_connection_tunnel2_addresses" {
  description = "Map of VPN connection key → Tunnel 2 outside IP."
  value       = { for k, v in aws_vpn_connection.this : k => v.tunnel2_address }
}

# ===========================================================================
# CLIENT VPN OUTPUTS
# ===========================================================================
output "client_vpn_endpoint_id" {
  description = "Client VPN endpoint ID."
  value       = try(aws_ec2_client_vpn_endpoint.this[0].id, null)
}

output "client_vpn_endpoint_arn" {
  description = "Client VPN endpoint ARN."
  value       = try(aws_ec2_client_vpn_endpoint.this[0].arn, null)
}

output "client_vpn_dns_name" {
  description = "DNS name for the Client VPN endpoint."
  value       = try(aws_ec2_client_vpn_endpoint.this[0].dns_name, null)
}

output "client_vpn_log_group_name" {
  description = "CloudWatch log group name for Client VPN connections."
  value       = try(aws_cloudwatch_log_group.client_vpn[0].name, null)
}
