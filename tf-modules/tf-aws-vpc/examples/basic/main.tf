provider "aws" { region = var.aws_region }

module "vpc" {
  source = "../../"

  name               = var.name
  environment        = var.environment
  project            = var.project
  owner              = var.owner
  cost_center        = var.cost_center
  tags               = var.tags
  cidr_block         = var.cidr_block
  availability_zones = var.availability_zones

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway # cost-saving for dev
}
