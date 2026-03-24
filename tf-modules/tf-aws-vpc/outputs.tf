output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC."
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Map of AZ → public subnet ID."
  value       = { for az, s in aws_subnet.public : az => s.id }
}

output "public_subnet_ids_list" {
  description = "List of public subnet IDs."
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "Map of AZ → private subnet ID."
  value       = { for az, s in aws_subnet.private : az => s.id }
}

output "private_subnet_ids_list" {
  description = "List of private subnet IDs."
  value       = [for s in aws_subnet.private : s.id]
}

output "database_subnet_ids" {
  description = "Map of AZ → database subnet ID."
  value       = { for az, s in aws_subnet.database : az => s.id }
}

output "database_subnet_ids_list" {
  description = "List of database subnet IDs."
  value       = [for s in aws_subnet.database : s.id]
}

output "database_subnet_group_id" {
  description = "The RDS DB subnet group ID (if created)."
  value       = length(aws_db_subnet_group.database) > 0 ? aws_db_subnet_group.database[0].id : null
}

output "database_subnet_group_name" {
  description = "The RDS DB subnet group name (if created)."
  value       = length(aws_db_subnet_group.database) > 0 ? aws_db_subnet_group.database[0].name : null
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway."
  value       = length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].id : null
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs."
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of Elastic IPs assigned to NAT Gateways."
  value       = aws_eip.nat[*].public_ip
}

output "vpn_gateway_id" {
  description = "The ID of the VPN Gateway."
  value       = length(aws_vpn_gateway.this) > 0 ? aws_vpn_gateway.this[0].id : null
}

output "flow_log_id" {
  description = "The ID of the VPC Flow Log."
  value       = length(aws_flow_log.this) > 0 ? aws_flow_log.this[0].id : null
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group used by flow logs."
  value       = local.flow_log_to_cloudwatch ? aws_cloudwatch_log_group.flow_log[0].arn : null
}

output "s3_endpoint_id" {
  description = "ID of the S3 Gateway endpoint."
  value       = length(aws_vpc_endpoint.s3) > 0 ? aws_vpc_endpoint.s3[0].id : null
}

output "interface_endpoint_ids" {
  description = "Map of interface endpoint key → endpoint ID."
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = length(aws_route_table.public) > 0 ? aws_route_table.public[0].id : null
}

output "private_route_table_ids" {
  description = "Map of AZ → private route table ID."
  value       = { for az, rt in aws_route_table.private : az => rt.id }
}
