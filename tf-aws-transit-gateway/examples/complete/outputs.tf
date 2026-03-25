output "tgw_id" {
  description = "The ID of the Transit Gateway."
  value       = module.tgw.tgw_id
}

output "route_table_ids" {
  description = "Map of custom TGW route table IDs."
  value       = module.tgw.route_table_ids
}

output "ram_share_arn" {
  description = "ARN of the RAM resource share."
  value       = module.tgw.ram_share_arn
}

output "tgw_arn" {
  description = "The ARN of the Transit Gateway."
  value       = module.tgw.tgw_arn
}

output "vpc_attachment_ids" {
  description = "Map of VPC attachment IDs."
  value       = module.tgw.vpc_attachment_ids
}
