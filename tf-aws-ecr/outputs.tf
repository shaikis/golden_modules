output "repository_urls" {
  description = "Map of repo key → repository URL."
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of repo key → repository ARN."
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}

output "repository_names" {
  description = "Map of repo key → full repository name."
  value       = { for k, v in aws_ecr_repository.this : k => v.name }
}

output "registry_id" {
  value = local.account_id
}
