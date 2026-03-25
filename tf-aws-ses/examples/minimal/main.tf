# Minimal SES setup -- one verified domain with DKIM.
# No configuration sets, no receipt rules, no templates, no IAM roles.
# Add feature flags incrementally as you need them.

module "ses" {
  source = "../../"

  domain_identities = {
    primary = {
      domain       = "example.com"
      dkim_signing = true
    }
  }
}

# Add these DNS CNAME records to your domain registrar:
output "dkim_records_to_add" {
  value = module.ses.dkim_cname_records
}
