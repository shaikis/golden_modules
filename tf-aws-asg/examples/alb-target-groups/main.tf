terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

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
      description = "KMS key for ${var.name} ASG instances attached to ALB target groups"
    }
  }
}

module "asg" {
  source = "../../"

  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  os_type                   = "linux"
  instance_type             = var.instance_type
  key_name                  = var.key_name
  kms_key_arn               = module.kms.key_arns["asg"]
  vpc_zone_identifier       = var.private_subnet_ids
  security_group_ids        = var.security_group_ids
  iam_instance_profile_name = var.iam_instance_profile_name

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 120

  target_group_arns = var.target_group_arns

  enable_cpu_scaling          = var.enable_cpu_scaling
  cpu_target_value            = var.cpu_target_value
  enable_alb_request_scaling  = var.enable_alb_request_scaling
  alb_request_target_value    = var.alb_request_target_value
  alb_target_group_arn_suffix = var.alb_target_group_arn_suffix
  alb_arn_suffix              = var.alb_arn_suffix

  tags = var.tags
}

output "asg_arn" {
  value = module.asg.asg_arn
}
