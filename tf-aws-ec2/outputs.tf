output "instance_ids" {
  value = {
    ondemand = { for k, v in aws_instance.this : k => v.id }
    spot     = { for k, v in aws_spot_instance_request.this : k => v.spot_instance_id }
  }
}

output "instance_arns" {
  value = {
    for k, v in aws_instance.this : k => v.arn
  }
}

output "private_ips" {
  value = merge(
    { for k, v in aws_instance.this : k => v.private_ip },
    { for k, v in aws_spot_instance_request.this : k => v.private_ip }
  )
}

output "public_ips" {
  value = merge(
    { for k, v in aws_instance.this : k => v.public_ip },
    { for k, v in aws_spot_instance_request.this : k => v.public_ip }
  )
}

output "private_dns" {
  value = merge(
    { for k, v in aws_instance.this : k => v.private_dns },
    { for k, v in aws_spot_instance_request.this : k => v.private_dns }
  )
}

output "public_dns" {
  value = merge(
    { for k, v in aws_instance.this : k => v.public_dns },
    { for k, v in aws_spot_instance_request.this : k => v.public_dns }
  )
}

output "availability_zones" {
  value = merge(
    { for k, v in aws_instance.this : k => v.availability_zone },
    { for k, v in aws_spot_instance_request.this : k => v.availability_zone }
  )
}

output "subnet_ids" {
  value = merge(
    { for k, v in aws_instance.this : k => v.subnet_id },
    { for k, v in aws_spot_instance_request.this : k => v.subnet_id }
  )
}

output "eip_public_ips" {
  value = { for k, v in aws_eip.this : k => v.public_ip }
}
