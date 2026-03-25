provider "aws" { region = var.aws_region }

module "tgw" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  vpc_attachments = var.vpc_attachments
}
