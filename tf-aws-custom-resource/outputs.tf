output "physical_resource_id" {
  description = "Physical ID returned by the custom resource Lambda (set as PhysicalResourceId in cfnresponse)."
  value       = aws_cloudformation_stack.custom_resource.outputs["ResourcePhysicalId"]
}

output "stack_id" {
  description = "CloudFormation stack ID."
  value       = aws_cloudformation_stack.custom_resource.id
}

output "stack_outputs" {
  description = "All raw CloudFormation stack outputs. Access individual values with stack_outputs[\"key\"]."
  value       = aws_cloudformation_stack.custom_resource.outputs
}

output "lambda_arn" {
  description = "ARN of the custom resource Lambda function."
  value       = local.lambda_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role. Empty if an external role was provided."
  value       = local.create_role ? aws_iam_role.lambda[0].arn : var.lambda_role_arn
}
