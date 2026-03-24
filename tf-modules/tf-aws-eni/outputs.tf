output "eni_ids" { value = { for k, v in aws_network_interface.this : k => v.id } }
output "eni_private_ips" { value = { for k, v in aws_network_interface.this : k => v.private_ip } }
output "eni_mac_addresses" { value = { for k, v in aws_network_interface.this : k => v.mac_address } }
output "eip_public_ips" { value = { for k, v in aws_eip.this : k => v.public_ip } }
output "eip_allocation_ids" { value = { for k, v in aws_eip.this : k => v.id } }
