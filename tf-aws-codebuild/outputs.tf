output "project_name" {
  description = "Name of the CodeBuild project."
  value       = aws_codebuild_project.this.name
}

output "project_arn" {
  description = "ARN of the CodeBuild project."
  value       = aws_codebuild_project.this.arn
}

output "project_id" {
  description = "ID of the CodeBuild project."
  value       = aws_codebuild_project.this.id
}

output "service_role_arn" {
  description = "ARN of the CodeBuild IAM service role."
  value       = aws_iam_role.codebuild.arn
}

output "service_role_name" {
  description = "Name of the CodeBuild IAM service role."
  value       = aws_iam_role.codebuild.name
}

output "log_group_name" {
  description = "CloudWatch Log Group name for build logs."
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.build[0].name : ""
}
