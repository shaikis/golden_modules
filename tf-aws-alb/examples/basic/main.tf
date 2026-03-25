provider "aws" { region = var.aws_region }

module "alb" {
  source      = "../../"
  name        = var.name
  vpc_id      = var.vpc_id
  subnets     = var.subnets
  environment = var.environment

  enable_deletion_protection = var.enable_deletion_protection

  target_groups = var.target_groups
  listeners     = var.listeners

  tags = var.tags
}
