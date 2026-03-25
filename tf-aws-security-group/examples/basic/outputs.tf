output "sg_id" {
  description = "The ID of the security group."
  value       = module.sg.security_group_id
}

output "sg_name" {
  description = "The name of the security group."
  value       = module.sg.security_group_name
}

output "sg_arn" {
  description = "The ARN of the security group."
  value       = module.sg.security_group_arn
}
