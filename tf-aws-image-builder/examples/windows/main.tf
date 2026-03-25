provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name        = "${var.name}-images"
  environment = var.environment
}

module "image_builder_windows" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  platform    = "Windows"
  kms_key_arn = module.kms.key_arn

  recipe_version               = var.recipe_version
  root_volume_size             = var.root_volume_size
  instance_types               = var.instance_types
  subnet_id                    = var.subnet_id
  security_group_ids           = var.security_group_ids
  pipeline_schedule_expression = var.pipeline_schedule_expression
  pipeline_enabled             = var.pipeline_enabled
  distribution_regions         = var.distribution_regions
  ami_launch_permissions       = var.ami_launch_permissions

  custom_components = var.custom_components
  components        = var.components
}

output "pipeline_arn" { value = module.image_builder_windows.pipeline_arn }
output "recipe_arn" { value = module.image_builder_windows.recipe_arn }
