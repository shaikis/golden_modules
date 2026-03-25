output "gateway_endpoint_ids" {
  value = { for k, v in aws_vpc_endpoint.gateway : k => v.id }
}

output "interface_endpoint_ids" {
  value = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "interface_endpoint_dns_entries" {
  description = "DNS entries for each interface endpoint."
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.dns_entry }
}
