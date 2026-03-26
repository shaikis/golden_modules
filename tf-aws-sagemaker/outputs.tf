# ============================================================
#  Domain Outputs
# ============================================================

output "domain_ids" {
  description = "Map of domain key to SageMaker domain ID."
  value       = { for k, v in aws_sagemaker_domain.this : k => v.id }
}

output "domain_arns" {
  description = "Map of domain key to SageMaker domain ARN."
  value       = { for k, v in aws_sagemaker_domain.this : k => v.arn }
}

# ============================================================
#  Notebook Outputs
# ============================================================

output "notebook_arns" {
  description = "Map of notebook key to notebook instance ARN."
  value       = { for k, v in aws_sagemaker_notebook_instance.this : k => v.arn }
}

output "notebook_urls" {
  description = "Map of notebook key to notebook instance URL."
  value       = { for k, v in aws_sagemaker_notebook_instance.this : k => v.url }
}

# ============================================================
#  Model Outputs
# ============================================================

output "model_arns" {
  description = "Map of model key to SageMaker model ARN."
  value       = { for k, v in aws_sagemaker_model.this : k => v.arn }
}

# ============================================================
#  Endpoint Outputs
# ============================================================

output "endpoint_arns" {
  description = "Map of endpoint key to SageMaker endpoint ARN."
  value       = { for k, v in aws_sagemaker_endpoint.this : k => v.arn }
}

output "endpoint_config_arns" {
  description = "Map of endpoint config key to SageMaker endpoint configuration ARN."
  value       = { for k, v in aws_sagemaker_endpoint_configuration.this : k => v.arn }
}

# ============================================================
#  Feature Group Outputs
# ============================================================

output "feature_group_arns" {
  description = "Map of feature group key to SageMaker Feature Group ARN."
  value       = { for k, v in aws_sagemaker_feature_group.this : k => v.arn }
}

# ============================================================
#  Pipeline Outputs
# ============================================================

output "pipeline_arns" {
  description = "Map of pipeline key to SageMaker Pipeline ARN."
  value       = { for k, v in aws_sagemaker_pipeline.this : k => v.arn }
}

# ============================================================
#  IAM Outputs
# ============================================================

output "iam_role_arn" {
  description = "ARN of the SageMaker execution IAM role (auto-created or passed via role_arn)."
  value       = var.create_iam_role ? aws_iam_role.sagemaker[0].arn : var.role_arn
}

output "iam_role_name" {
  description = "Name of the auto-created SageMaker execution IAM role. Null when BYO role is used."
  value       = var.create_iam_role ? aws_iam_role.sagemaker[0].name : null
}
