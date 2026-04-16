output "instance_ids" {
  description = "IDs of on-demand and spot instances."
  value = {
    ondemand = { for k, v in aws_instance.this : k => v.id }
    spot     = { for k, v in aws_spot_instance_request.this : k => v.spot_instance_id }
  }
}

output "instance_arns" {
  description = "ARNs of on-demand instances."
  value       = { for k, v in aws_instance.this : k => v.arn }
}

output "private_ips" {
  description = "Private IPs for all instances."
  value = merge(
    { for k, v in aws_instance.this : k => v.private_ip },
    { for k, v in aws_spot_instance_request.this : k => v.private_ip }
  )
}

output "public_ips" {
  description = "Public IPs for all instances."
  value = merge(
    { for k, v in aws_instance.this : k => v.public_ip },
    { for k, v in aws_spot_instance_request.this : k => v.public_ip }
  )
}

output "private_dns" {
  description = "Private DNS names for all instances."
  value = merge(
    { for k, v in aws_instance.this : k => v.private_dns },
    { for k, v in aws_spot_instance_request.this : k => v.private_dns }
  )
}

output "public_dns" {
  description = "Public DNS names for all instances."
  value = merge(
    { for k, v in aws_instance.this : k => v.public_dns },
    { for k, v in aws_spot_instance_request.this : k => v.public_dns }
  )
}

output "availability_zones" {
  description = "Availability zones for all instances."
  value = merge(
    { for k, v in aws_instance.this : k => v.availability_zone },
    { for k, v in aws_spot_instance_request.this : k => v.availability_zone }
  )
}

output "subnet_ids" {
  description = "Subnet IDs for all instances."
  value = merge(
    { for k, v in aws_instance.this : k => v.subnet_id },
    { for k, v in aws_spot_instance_request.this : k => v.subnet_id }
  )
}

output "eip_public_ips" {
  description = "Elastic IPs for on-demand instances that requested them."
  value       = { for k, v in aws_eip.this : k => v.public_ip }
}
