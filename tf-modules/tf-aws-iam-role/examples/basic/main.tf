provider "aws" { region = var.aws_region }

module "ec2_role" {
  source = "../../"
  name   = var.name

  trusted_role_services   = var.trusted_role_services
  create_instance_profile = var.create_instance_profile

  managed_policy_arns = var.managed_policy_arns
}

output "role_arn" { value = module.ec2_role.role_arn }
output "instance_profile_arn" { value = module.ec2_role.instance_profile_arn }
