output "lexicon_names" {
  description = "Map of lexicon names."
  value       = { for k, v in aws_polly_lexicon.this : k => v.name }
}

output "lexicon_arns" {
  description = "Map of lexicon ARNs."
  value       = { for k, v in aws_polly_lexicon.this : k => v.arn }
}

output "iam_role_arn" {
  description = "IAM role ARN used for Polly access."
  value       = local.role_arn
}

output "iam_role_name" {
  description = "IAM role name."
  value       = var.create_iam_role ? aws_iam_role.polly[0].name : null
}
