output "instance_id" { value = module.ec2.instance_id }
output "instance_arn" { value = module.ec2.instance_arn }
output "private_ip" { value = module.ec2.private_ip }
output "public_ip" { value = module.ec2.public_ip }
output "eip_public_ip" {
  description = "Elastic IP (null when create_eip = false)"
  value       = module.ec2.public_ip
}
output "kms_key_arn" { value = module.kms.key_arn }
output "iam_role_arn" { value = module.role.iam_role_arn }
output "security_group_id" { value = module.sg.security_group_id }
