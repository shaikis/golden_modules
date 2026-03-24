locals {
  prefix = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  common_tags = merge(
    {
      Name        = local.prefix
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "tf-aws-route53"
    },
    var.tags
  )

  # Resolve zone ID: BYO takes priority over module-created zone
  zone_id_map = {
    for k, z in var.zones :
    k => (
      z.zone_id != null ? z.zone_id :
      contains(keys(aws_route53_zone.this), k) ? aws_route53_zone.this[k].zone_id : null
    )
  }
}
