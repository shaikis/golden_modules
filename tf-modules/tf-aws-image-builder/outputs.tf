output "pipeline_arn" { value = aws_imagebuilder_image_pipeline.this.arn }
output "recipe_arn" { value = aws_imagebuilder_image_recipe.this.arn }
output "infra_config_arn" { value = aws_imagebuilder_infrastructure_configuration.this.arn }
output "dist_config_arn" { value = aws_imagebuilder_distribution_configuration.this.arn }
output "instance_profile_arn" { value = aws_iam_instance_profile.instance.arn }
output "custom_component_arns" { value = { for k, v in aws_imagebuilder_component.custom : k => v.arn } }
