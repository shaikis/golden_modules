# =============================================================================
# Example: Basic Public Hosted Zone
#
# Creates a single public hosted zone with common record types:
#   - A      (zone apex → IPv4)
#   - AAAA   (zone apex → IPv6)
#   - CNAME  (www → apex)
#   - MX     (email routing)
#   - TXT    (SPF, DMARC, domain verification)
#   - NS     (subdomain delegation)
#   - CAA    (certificate authority authorization)
# =============================================================================

module "route53" {
  source = "../../"

  name        = "basic"
  name_prefix = var.name_prefix
  environment = var.environment
  tags        = var.tags

  # ── Hosted Zone ─────────────────────────────────────────────────────────────
  zones = {
    main = {
      name    = var.zone_name
      comment = "Basic public hosted zone managed by Terraform"
    }
  }

  # ── DNS Records ──────────────────────────────────────────────────────────────
  records = {
    # Zone apex A record — points root domain to an IP address
    apex_a = {
      zone_key = "main"
      name     = var.zone_name
      type     = "A"
      ttl      = 300
      records  = [var.root_ip]
    }

    # Zone apex AAAA record — IPv6 for the root domain
    apex_aaaa = {
      zone_key = "main"
      name     = var.zone_name
      type     = "AAAA"
      ttl      = 300
      records  = [var.root_ipv6]
    }

    # www CNAME — redirect www to the apex domain
    www_cname = {
      zone_key = "main"
      name     = "www.${var.zone_name}"
      type     = "CNAME"
      ttl      = 300
      records  = [var.zone_name]
    }

    # MX records — email routing (priority + mail server FQDN)
    mail_mx = {
      zone_key = "main"
      name     = var.zone_name
      type     = "MX"
      ttl      = 3600
      records  = var.email_mx_records
    }

    # SPF TXT record — defines authorized mail senders to prevent spoofing
    spf_txt = {
      zone_key = "main"
      name     = var.zone_name
      type     = "TXT"
      ttl      = 3600
      records  = ["\"${var.spf_record}\""]
    }

    # DMARC TXT record — domain-based message authentication policy
    dmarc_txt = {
      zone_key = "main"
      name     = "_dmarc.${var.zone_name}"
      type     = "TXT"
      ttl      = 3600
      records  = ["\"${var.dmarc_record}\""]
    }

    # Domain verification TXT — for external services (e.g. Google Search Console)
    verification_txt = {
      zone_key = "main"
      name     = var.zone_name
      type     = "TXT"
      ttl      = 3600
      records  = ["\"google-site-verification=abc123def456\""]
    }

    # NS record for subdomain delegation — delegate staging.example.com to another zone
    staging_ns_delegation = {
      zone_key = "main"
      name     = "staging.${var.zone_name}"
      type     = "NS"
      ttl      = 172800 # 48 hours — NS records should have long TTLs
      records = [
        "ns-100.awsdns-12.com.",
        "ns-200.awsdns-25.net.",
        "ns-300.awsdns-37.org.",
        "ns-400.awsdns-50.co.uk.",
      ]
    }

    # CAA record — restrict which Certificate Authorities can issue TLS certs
    # This only allows Let's Encrypt and Amazon to issue certificates
    apex_caa = {
      zone_key = "main"
      name     = var.zone_name
      type     = "CAA"
      ttl      = 3600
      records = [
        "0 issue \"letsencrypt.org\"",
        "0 issue \"amazon.com\"",
        "0 issuewild \"letsencrypt.org\"",
        "0 iodef \"mailto:security@example.com\"",
      ]
    }
  }
}
