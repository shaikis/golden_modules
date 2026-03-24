output "vpc_id" {
  description = "The ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = module.vpc.public_subnet_ids_list
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = module.vpc.private_subnet_ids_list
}

output "database_subnet_ids" {
  description = "List of database subnet IDs."
  value       = module.vpc.database_subnet_ids_list
}

output "database_subnet_group" {
  description = "Name of the database subnet group."
  value       = module.vpc.database_subnet_group_name
}

output "nat_gateway_public_ips" {
  description = "Public IPs of NAT Gateways."
  value       = module.vpc.nat_gateway_public_ips
}
