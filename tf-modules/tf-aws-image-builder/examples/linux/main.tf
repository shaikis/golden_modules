provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name        = "${var.name}-images"
  environment = var.environment
}

module "image_builder_linux" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  platform    = "Linux"
  kms_key_arn = module.kms.key_arn

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

output "pipeline_arn" { value = module.image_builder_linux.pipeline_arn }
output "recipe_arn" { value = module.image_builder_linux.recipe_arn }
