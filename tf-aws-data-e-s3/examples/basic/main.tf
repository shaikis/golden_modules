provider "aws" { region = var.aws_region }

module "s3" {
  source      = "../../"
  bucket_name = var.bucket_name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags
}
