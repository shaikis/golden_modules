locals {
  common_tags = merge(var.tags, {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ── ACM Certificate ─────────────────────────────────────────────────────────────
resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = var.validation_method
  key_algorithm             = var.key_algorithm

  options {
    certificate_transparency_logging_preference = var.transparency_logging ? "ENABLED" : "DISABLED"
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# ── DNS Validation Records (Route 53) ──────────────────────────────────────────
# One CNAME record per unique domain (ACM deduplicates SANs automatically)
resource "aws_route53_record" "validation" {
  for_each = var.validation_method == "DNS" && var.route53_zone_id != null ? {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# ── Certificate Validation Waiter ───────────────────────────────────────────────
resource "aws_acm_certificate_validation" "this" {
  count = var.wait_for_validation && var.validation_method == "DNS" && var.route53_zone_id != null ? 1 : 0

  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]

  timeouts {
    create = "30m"
  }
}
