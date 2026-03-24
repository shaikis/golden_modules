output "tgw_id" {
  description = "The ID of the Transit Gateway."
  value       = module.tgw.tgw_id
}

output "tgw_arn" {
  description = "The ARN of the Transit Gateway."
  value       = module.tgw.tgw_arn
}

output "vpc_attachment_ids" {
  description = "Map of VPC attachment IDs."
  value       = module.tgw.vpc_attachment_ids
}
