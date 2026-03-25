provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name        = "${var.name}-ecr"
  environment = var.environment
}

module "ecr" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  kms_key_arn = module.kms.key_arn

  repositories        = var.repositories
  push_principal_arns = var.push_principal_arns
  cross_account_ids   = var.cross_account_ids
}

output "repository_urls" { value = module.ecr.repository_urls }
