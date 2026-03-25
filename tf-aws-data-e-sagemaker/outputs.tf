# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "domain_arns" {
  description = "Map of domain name to SageMaker domain ARN."
  value       = { for k, v in aws_sagemaker_domain.this : k => v.arn }
}

output "domain_ids" {
  description = "Map of domain name to SageMaker domain ID."
  value       = { for k, v in aws_sagemaker_domain.this : k => v.id }
}

output "pipeline_arns" {
  description = "Map of pipeline name to SageMaker Pipeline ARN."
  value       = { for k, v in aws_sagemaker_pipeline.this : k => v.arn }
}

output "model_arns" {
  description = "Map of model name to SageMaker Model ARN."
  value       = { for k, v in aws_sagemaker_model.this : k => v.arn }
}

output "endpoint_config_arns" {
  description = "Map of endpoint configuration name to ARN."
  value       = { for k, v in aws_sagemaker_endpoint_configuration.this : k => v.arn }
}

output "endpoint_arns" {
  description = "Map of endpoint name to SageMaker Endpoint ARN."
  value       = { for k, v in aws_sagemaker_endpoint.this : k => v.arn }
}

output "feature_group_arns" {
  description = "Map of feature group name to SageMaker Feature Group ARN."
  value       = { for k, v in aws_sagemaker_feature_group.this : k => v.arn }
}

output "user_profile_arns" {
  description = "Map of user profile name to SageMaker User Profile ARN."
  value       = { for k, v in aws_sagemaker_user_profile.this : k => v.arn }
}

output "sagemaker_role_arn" {
  description = "ARN of the SageMaker execution role (null when create_iam_role = false and role_arn not set)."
  value       = local.effective_role_arn
}

output "alarm_arns" {
  description = "Map of alarm name to CloudWatch alarm ARN."
  value = var.create_alarms ? merge(
    { for k, v in aws_cloudwatch_metric_alarm.invocations : "${k}-invocations-low" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.model_latency_p99 : "${k}-model-latency-p99" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.errors_4xx : "${k}-4xx-errors" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.errors_5xx : "${k}-5xx-errors" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.invocation_model_errors : "${k}-invocation-model-errors" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.cpu_utilization : "${k}-cpu-utilization" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.memory_utilization : "${k}-memory-utilization" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.disk_utilization : "${k}-disk-utilization" => v.arn },
  ) : {}
}
