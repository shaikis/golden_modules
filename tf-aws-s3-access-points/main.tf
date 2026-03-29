locals {
  access_points_by_name = {
    for access_point in var.access_points : access_point.name => access_point
  }
}

resource "aws_s3_access_point" "this" {
  for_each = local.access_points_by_name

  bucket            = var.bucket
  bucket_account_id = var.bucket_account_id
  name              = each.value.name
  policy            = each.value.policy
  tags              = merge(var.tags, each.value.tags)

  dynamic "vpc_configuration" {
    for_each = each.value.vpc_id != null ? [each.value.vpc_id] : []
    content {
      vpc_id = vpc_configuration.value
    }
  }

  dynamic "public_access_block_configuration" {
    for_each = each.value.public_access_block_configuration != null ? [each.value.public_access_block_configuration] : []
    content {
      block_public_acls       = public_access_block_configuration.value.block_public_acls
      block_public_policy     = public_access_block_configuration.value.block_public_policy
      ignore_public_acls      = public_access_block_configuration.value.ignore_public_acls
      restrict_public_buckets = public_access_block_configuration.value.restrict_public_buckets
    }
  }
}
