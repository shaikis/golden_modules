provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name_prefix = var.name
  tags = {
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
  }

  keys = {
    asg = {
      description = "KMS key for ${var.name} ASG instances"
    }
  }
}

module "asg_linux" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  os_type                   = "linux"
  instance_type             = var.instance_type
  kms_key_arn               = module.kms.key_arns["asg"]
  vpc_zone_identifier       = var.subnet_ids
  security_group_ids        = var.security_group_ids
  iam_instance_profile_name = var.iam_instance_profile_name

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  enable_cpu_scaling = var.enable_cpu_scaling
  cpu_target_value   = var.cpu_target_value

  scheduled_actions = var.scheduled_actions

  tags = var.tags
}

output "asg_name" { value = module.asg_linux.asg_name }
output "hostname_prefix" { value = module.asg_linux.hostname_prefix }
