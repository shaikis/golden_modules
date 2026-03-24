output "domain_identity_arns" {
  description = "SES domain identity ARNs."
  value       = module.ses.domain_identity_arns
}

output "email_identity_arns" {
  description = "SES email address identity ARNs."
  value       = module.ses.email_identity_arns
}

output "dkim_tokens" {
  description = "DKIM tokens per domain (add as CNAME records to DNS)."
  value       = module.ses.dkim_tokens
}

output "dkim_cname_records" {
  description = "Ready-to-use DKIM CNAME records: name → value pairs for each domain."
  value       = module.ses.dkim_cname_records
}

output "mail_from_domains" {
  description = "Configured MAIL FROM domains."
  value       = module.ses.mail_from_domains
}

output "configuration_set_arns" {
  description = "SES configuration set ARNs."
  value       = module.ses.configuration_set_arns
}

output "receipt_rule_set_names" {
  description = "SES receipt rule set names."
  value       = module.ses.receipt_rule_set_names
}

output "receipt_rule_arns" {
  description = "SES receipt rule ARNs."
  value       = module.ses.receipt_rule_arns
}

output "template_names" {
  description = "SES email template names."
  value       = module.ses.template_names
}

output "ses_firehose_role_arn" {
  description = "IAM role ARN for SES → Firehose delivery."
  value       = module.ses.ses_firehose_role_arn
}

output "ses_s3_role_arn" {
  description = "IAM role ARN for SES → S3 inbound mail."
  value       = module.ses.ses_s3_role_arn
}

output "ses_sending_iam_policy_json" {
  description = "JSON policy document to attach to application roles for SES sending."
  value       = module.ses.ses_sending_iam_policy_json
  sensitive   = false
}

output "aws_region" {
  description = "AWS region of deployed SES resources."
  value       = module.ses.aws_region
}
