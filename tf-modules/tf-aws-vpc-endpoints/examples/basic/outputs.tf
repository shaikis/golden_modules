output "gateway_endpoint_ids" { value = module.vpc_endpoints.gateway_endpoint_ids }
output "interface_endpoint_ids" { value = module.vpc_endpoints.interface_endpoint_ids }
output "interface_endpoint_dns_entries" { value = module.vpc_endpoints.interface_endpoint_dns_entries }
