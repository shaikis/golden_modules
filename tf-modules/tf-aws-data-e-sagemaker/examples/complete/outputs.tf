output "domain_ids" {
  description = "SageMaker Studio domain IDs."
  value       = module.sagemaker.domain_ids
}

output "domain_arns" {
  description = "SageMaker Studio domain ARNs."
  value       = module.sagemaker.domain_arns
}

output "pipeline_arns" {
  description = "SageMaker Pipeline ARNs."
  value       = module.sagemaker.pipeline_arns
}

output "model_arns" {
  description = "SageMaker Model ARNs."
  value       = module.sagemaker.model_arns
}

output "endpoint_arns" {
  description = "SageMaker Endpoint ARNs."
  value       = module.sagemaker.endpoint_arns
}

output "feature_group_arns" {
  description = "SageMaker Feature Group ARNs."
  value       = module.sagemaker.feature_group_arns
}

output "sagemaker_role_arn" {
  description = "SageMaker execution role ARN."
  value       = module.sagemaker.sagemaker_role_arn
}

output "alarm_arns" {
  description = "CloudWatch alarm ARNs."
  value       = module.sagemaker.alarm_arns
}
