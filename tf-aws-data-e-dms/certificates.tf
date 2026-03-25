resource "aws_dms_certificate" "this" {
  for_each = var.create_certificates ? var.certificates : {}

  certificate_id     = each.value.certificate_id
  certificate_pem    = each.value.certificate_pem
  certificate_wallet = each.value.certificate_wallet

  tags = merge(var.tags, each.value.tags)
}
