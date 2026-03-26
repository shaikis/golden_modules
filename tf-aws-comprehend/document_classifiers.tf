# ---------------------------------------------------------------------------
# aws_comprehend_document_classifier
# Enabled only when var.create_document_classifiers = true.
# Each entry in var.document_classifiers creates one classifier.
# ---------------------------------------------------------------------------

resource "aws_comprehend_document_classifier" "this" {
  for_each = var.create_document_classifiers ? var.document_classifiers : {}

  name                 = "${local.name_prefix}${each.key}"
  language_code        = each.value.language_code
  mode                 = each.value.mode
  data_access_role_arn = local.role_arn

  # Optional: version name for the classifier model
  version_name = each.value.version_name

  # ---------------------------------------------------------------------------
  # Training & test data
  # ---------------------------------------------------------------------------
  input_data_config {
    s3_uri          = each.value.s3_uri
    test_s3_uri     = each.value.test_s3_uri
    label_delimiter = each.value.label_delimiter
  }

  # ---------------------------------------------------------------------------
  # KMS encryption
  # Per-resource key takes precedence; falls back to module-level key.
  # ---------------------------------------------------------------------------
  model_kms_key_id  = coalesce(each.value.model_kms_key_id, var.kms_key_arn)
  volume_kms_key_id = coalesce(each.value.volume_kms_key_id, var.volume_kms_key_arn)

  # ---------------------------------------------------------------------------
  # VPC configuration (optional)
  # ---------------------------------------------------------------------------
  dynamic "vpc_config" {
    for_each = each.value.vpc_config != null ? [each.value.vpc_config] : []

    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnets            = vpc_config.value.subnets
    }
  }

  tags = merge(local.tags, each.value.tags)
}
