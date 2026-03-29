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
      description = "KMS key for ${var.name} Windows ASG instances"
    }
  }
}

module "asg_windows" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  os_type                   = "windows"
  instance_type             = var.instance_type
  kms_key_arn               = module.kms.key_arns["asg"]
  vpc_zone_identifier       = var.subnet_ids
  security_group_ids        = var.security_group_ids
  iam_instance_profile_name = var.iam_instance_profile_name

  windows_domain_name            = var.windows_domain_name
  windows_domain_join_secret_arn = var.windows_domain_join_secret_arn

  root_volume_size = var.root_volume_size

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  use_mixed_instances_policy      = var.use_mixed_instances_policy
  on_demand_base_capacity         = var.on_demand_base_capacity
  on_demand_percentage_above_base = var.on_demand_percentage_above_base
  override_instance_types         = var.override_instance_types

  enable_cpu_scaling    = var.enable_cpu_scaling
  cpu_target_value      = var.cpu_target_value
  enable_memory_scaling = var.enable_memory_scaling
  memory_target_value   = var.memory_target_value

  scheduled_actions = var.scheduled_actions
  tags              = var.tags
}

output "hostname_prefix" {
  value = module.asg_windows.hostname_prefix
}
