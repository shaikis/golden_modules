# ===========================================================================
# ECR REPOSITORIES
# ===========================================================================
resource "aws_ecr_repository" "this" {
  for_each = var.repositories

  name                 = "${local.name}/${each.key}"
  image_tag_mutability = each.value.image_tag_mutability
  force_delete         = each.value.force_delete

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  encryption_configuration {
    encryption_type = each.value.encryption_type
    kms_key         = each.value.encryption_type == "KMS" ? var.kms_key_arn : null
  }

  tags = merge(local.tags, each.value.additional_tags)

  lifecycle {
    prevent_destroy = true
  }
}
