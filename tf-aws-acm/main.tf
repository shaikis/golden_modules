locals {
  common_tags = merge(var.tags, {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # Build a unified zone-id lookup: per-domain map takes precedence, then
  # fall back to the single route53_zone_id for every domain.
  # Result: { "example.com" = "Z123...", "api.other.com" = "Z456..." }
  zone_id_lookup = length(var.route53_zone_ids) > 0 ? var.route53_zone_ids : (
    var.route53_zone_id != null ? {
      for domain in concat([var.domain_name], var.subject_alternative_names) :
      domain => var.route53_zone_id
    } : {}
  )

  # DNS validation is possible only when we have zone ids and a public cert
  do_dns_validation = (
    var.validation_method == "DNS" &&
    var.certificate_authority_arn == null &&  # Private CA = no validation needed
    length(local.zone_id_lookup) > 0
  )
}

# ── ACM Certificate ─────────────────────────────────────────────────────────────
resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  key_algorithm             = var.key_algorithm

  # Private CA: omit validation_method; set certificate_authority_arn
  validation_method         = var.certificate_authority_arn != null ? null : var.validation_method
  certificate_authority_arn = var.certificate_authority_arn

  # Trigger early renewal before expiry (useful for Private CA certs)
  early_renewal_duration = var.early_renewal_duration

  options {
    certificate_transparency_logging_preference = var.transparency_logging ? "ENABLED" : "DISABLED"
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# ── DNS Validation Records (Route 53) ──────────────────────────────────────────
# One CNAME per unique domain.  Each record looks up its own zone_id from
# local.zone_id_lookup — supports SANs in different hosted zones.
resource "aws_route53_record" "validation" {
  for_each = local.do_dns_validation ? {
    for dvo in aws_acm_certificate.this.domain_validation_options :
    dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = lookup(local.zone_id_lookup, dvo.domain_name, null)
    }
    if lookup(local.zone_id_lookup, dvo.domain_name, null) != null
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

# ── Certificate Validation Waiter ───────────────────────────────────────────────
resource "aws_acm_certificate_validation" "this" {
  count = var.wait_for_validation && local.do_dns_validation ? 1 : 0

  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]

  timeouts {
    create = "30m"
  }
}
