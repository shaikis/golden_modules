provider "aws" { region = var.aws_region }

module "secret" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  description = var.description
  tags        = var.tags
}
