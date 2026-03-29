provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name_prefix = "${var.name}-images"
  tags = {
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
  }

  keys = {
    image_builder = {
      description = "KMS key for ${var.name} Linux Image Builder pipeline"
    }
  }
}

module "image_builder_linux" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  platform    = "Linux"
  kms_key_arn = module.kms.key_arns["image_builder"]

  recipe_version               = var.recipe_version
  root_volume_size             = var.root_volume_size
  instance_types               = var.instance_types
  subnet_id                    = var.subnet_id
  security_group_ids           = var.security_group_ids
  pipeline_schedule_expression = var.pipeline_schedule_expression
  pipeline_enabled             = var.pipeline_enabled
  distribution_regions         = var.distribution_regions

  custom_components = var.custom_components
  components        = var.components
}
