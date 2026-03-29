output "pipeline_arn" { value = module.image_builder.pipeline_arn }
output "recipe_arn" { value = module.image_builder.recipe_arn }
output "custom_component_arns" { value = module.image_builder.custom_component_arns }
output "artifacts_bucket" { value = module.s3_artifacts.bucket_id }
output "packer_template_s3" { value = "s3://${module.s3_artifacts.bucket_id}/${aws_s3_object.packer_template.key}" }
