resource "aws_athena_database" "this" {
  for_each = var.databases

  name          = each.key
  bucket        = each.value.bucket
  comment       = each.value.comment
  force_destroy = each.value.force_destroy

  encryption_configuration {
    encryption_option = each.value.encryption_type
    key_arn           = each.value.kms_key_arn
  }

  dynamic "acl_configuration" {
    for_each = each.value.expected_bucket_owner != null ? [each.value.expected_bucket_owner] : []

    content {
      s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
    }
  }

  expected_bucket_owner = each.value.expected_bucket_owner

  properties = each.value.properties
}
