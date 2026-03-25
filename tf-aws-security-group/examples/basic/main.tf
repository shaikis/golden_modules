provider "aws" { region = var.aws_region }

module "sg" {
  source      = "../../"
  name        = var.name
  vpc_id      = var.vpc_id
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  ingress_rules = var.ingress_rules
}
