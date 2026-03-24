# =============================================================================
# tf-aws-route53 — DNSSEC
#
# DNSSEC protects against DNS spoofing and cache poisoning attacks.
# Requires a KMS asymmetric key in us-east-1 for key signing.
#
# Two-step process:
#   1. Create a KMS key (ECC_NIST_P256, key usage: SIGN_VERIFY) in us-east-1
#   2. Create a key signing key (KSK) in Route 53 → references the KMS key
#   3. Enable DNSSEC signing on the hosted zone
#
# After enabling:
#   - DS records must be added to the parent zone (your registrar or parent zone)
#   - Monitoring: set up CloudWatch alarm on DNSSECInternalFailure metric
#
# IMPORTANT: DNSSEC KMS keys MUST be in us-east-1 regardless of your region.
#
# To enable: set enable_dnssec = true in the zone config
# =============================================================================

variable "dnssec_zones" {
  description = <<-EOT
    Map of zones to enable DNSSEC on.
    Key must match a key in var.zones (zone must be created by this module, not BYO).

    Each entry creates:
      - A KMS key signing key (KSK) in Route 53
      - Enables DNSSEC on the hosted zone
      - Outputs the DS record value to add to the parent zone/registrar

    Prerequisites:
      - The KMS key must exist in us-east-1 (provide kms_key_arn)
      - Or set create_kms_key = true (module creates the key in us-east-1)

    Example:
      main = {
        kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/..."
      }
  EOT
  type = map(object({
    # ARN of an existing KMS asymmetric key (ECC_NIST_P256, SIGN_VERIFY) in us-east-1
    # Mutually exclusive with create_kms_key = true
    kms_key_arn = optional(string, null)

    # Name for the key signing key in Route 53 (1-128 chars, alphanumeric + _)
    key_signing_key_name = optional(string, "KSK1")

    # DNSSEC signing status: "SIGNING" or "NOT_SIGNING"
    signing_status = optional(string, "SIGNING")
  }))
  default = {}
}

resource "aws_route53_key_signing_key" "this" {
  for_each = var.dnssec_zones

  hosted_zone_id             = aws_route53_zone.this[each.key].id
  key_management_service_arn = each.value.kms_key_arn
  name                       = each.value.key_signing_key_name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_hosted_zone_dnssec" "this" {
  for_each = var.dnssec_zones

  hosted_zone_id = aws_route53_key_signing_key.this[each.key].hosted_zone_id
  signing_status = each.value.signing_status

  depends_on = [aws_route53_key_signing_key.this]
}
