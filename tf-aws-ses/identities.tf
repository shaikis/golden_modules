# ── Domain Identities ──────────────────────────────────────────────────────────

resource "aws_sesv2_email_identity" "domain" {
  for_each = var.domain_identities

  email_identity         = each.value.domain
  configuration_set_name = each.value.configuration_set_name

  tags = merge(var.tags, each.value.tags)
}

# ── Easy DKIM (RSA_2048_BIT) per domain ────────────────────────────────────────

resource "aws_sesv2_email_identity_dkim_signing_attributes" "domain" {
  for_each = {
    for k, v in var.domain_identities : k => v
    if v.dkim_signing
  }

  email_identity            = aws_sesv2_email_identity.domain[each.key].email_identity
  signing_attributes_origin = "AWS_SES"
}

# ── MAIL FROM attributes per domain ────────────────────────────────────────────

resource "aws_sesv2_email_identity_mail_from_attributes" "domain" {
  for_each = {
    for k, v in var.domain_identities : k => v
    if v.mail_from_domain != null
  }

  email_identity         = aws_sesv2_email_identity.domain[each.key].email_identity
  mail_from_domain       = each.value.mail_from_domain
  behavior_on_mx_failure = each.value.mail_from_behavior_on_mx_failure
}

# ── Legacy v1 DKIM tokens (for DNS record output) ──────────────────────────────

resource "aws_ses_domain_dkim" "domain" {
  for_each = {
    for k, v in var.domain_identities : k => v
    if v.dkim_signing
  }

  domain = each.value.domain

  depends_on = [aws_sesv2_email_identity.domain]
}

# ── Email Address Identities ───────────────────────────────────────────────────

resource "aws_sesv2_email_identity" "email" {
  for_each = var.email_identities

  email_identity         = each.value.email_address
  configuration_set_name = each.value.configuration_set_name

  tags = var.tags
}
