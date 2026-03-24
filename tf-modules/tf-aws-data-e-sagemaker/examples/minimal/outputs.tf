output "domain_ids" {
  description = "SageMaker domain IDs."
  value       = module.sagemaker.domain_ids
}

output "sagemaker_role_arn" {
  description = "SageMaker execution role ARN."
  value       = module.sagemaker.sagemaker_role_arn
}
