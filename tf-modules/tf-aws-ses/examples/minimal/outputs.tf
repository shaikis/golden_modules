output "domain_identity_arns" {
  value = module.ses.domain_identity_arns
}

output "dkim_cname_records" {
  description = "Add these 3 CNAME records to your DNS to enable DKIM."
  value       = module.ses.dkim_cname_records
}
