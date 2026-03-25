# ── Identity ARNs ──────────────────────────────────────────────────────────────

output "domain_identity_arns" {
  description = "Map of logical identity key → SES domain identity ARN."
  value       = { for k, v in aws_sesv2_email_identity.domain : k => v.arn }
}

output "domain_identity_names" {
  description = "Map of logical identity key → domain name string."
  value       = { for k, v in aws_sesv2_email_identity.domain : k => v.email_identity }
}

output "email_identity_arns" {
  description = "Map of logical identity key → SES email address identity ARN."
  value       = { for k, v in aws_sesv2_email_identity.email : k => v.arn }
}

# ── DKIM ───────────────────────────────────────────────────────────────────────

output "dkim_tokens" {
  description = "Map of logical identity key → list of DKIM tokens (use for DNS CNAME records)."
  value       = { for k, v in aws_ses_domain_dkim.domain : k => v.dkim_tokens }
}

output "dkim_cname_records" {
  description = <<-EOT
    Map of logical identity key → list of objects { name, value } representing
    the DNS CNAME records that must be added to verify DKIM.
    name  = "<token>._domainkey.<domain>"
    value = "<token>.dkim.amazonses.com"
  EOT
  value = {
    for k, dkim in aws_ses_domain_dkim.domain : k => [
      for token in dkim.dkim_tokens : {
        name  = "${token}._domainkey.${var.domain_identities[k].domain}"
        value = "${token}.dkim.amazonses.com"
      }
    ]
  }
}

# ── MAIL FROM ─────────────────────────────────────────────────────────────────

output "mail_from_domains" {
  description = "Map of logical identity key → configured MAIL FROM domain."
  value = {
    for k, v in aws_sesv2_email_identity_mail_from_attributes.domain :
    k => v.mail_from_domain
  }
}

# ── Configuration Sets ─────────────────────────────────────────────────────────

output "configuration_set_arns" {
  description = "Map of configuration set name → ARN. Empty when create_configuration_sets=false."
  value       = try({ for k, v in aws_sesv2_configuration_set.this : k => v.arn }, {})
}

# ── Receipt Rules ──────────────────────────────────────────────────────────────

output "receipt_rule_set_names" {
  description = "Map of rule set key → rule set name. Empty when create_receipt_rules=false."
  value       = try({ for k, v in aws_ses_receipt_rule_set.this : k => v.rule_set_name }, {})
}

output "receipt_rule_arns" {
  description = "Map of receipt rule key → rule ARN. Empty when create_receipt_rules=false."
  value       = try({ for k, v in aws_ses_receipt_rule.this : k => v.arn }, {})
}

# ── Templates ──────────────────────────────────────────────────────────────────

output "template_names" {
  description = "List of SES template names created by this module. Empty when create_templates=false."
  value       = try([for k, v in aws_ses_template.this : v.name], [])
}

# ── IAM ────────────────────────────────────────────────────────────────────────

output "ses_firehose_role_arn" {
  description = "ARN of the IAM role used by SES to write events to Kinesis Firehose. Null if neither create_iam_roles nor create_firehose_role is true."
  value       = try(aws_iam_role.ses_firehose[0].arn, null)
}

output "ses_s3_role_arn" {
  description = "ARN of the IAM role used by SES to deliver inbound mail to S3. Null if neither create_iam_roles nor create_s3_role is true."
  value       = try(aws_iam_role.ses_s3[0].arn, null)
}

output "ses_sending_iam_policy_json" {
  description = "JSON policy document granting ses:SendEmail and ses:SendRawEmail. Attach to application IAM roles."
  value       = data.aws_iam_policy_document.ses_sending.json
}

# ── Misc ───────────────────────────────────────────────────────────────────────

output "aws_region" {
  description = "AWS region where SES resources are deployed."
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID where SES resources are deployed."
  value       = data.aws_caller_identity.current.account_id
}
