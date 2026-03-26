# ---------------------------------------------------------------------------
# aws_comprehend_entity_recognizer
# Enabled only when var.create_entity_recognizers = true.
# Each entry in var.entity_recognizers creates one recognizer.
# ---------------------------------------------------------------------------

resource "aws_comprehend_entity_recognizer" "this" {
  for_each = var.create_entity_recognizers ? var.entity_recognizers : {}

  name                 = "${local.name_prefix}${each.key}"
  language_code        = each.value.language_code
  data_access_role_arn = local.role_arn

  # Optional: version name for the recognizer model
  version_name = each.value.version_name

  # ---------------------------------------------------------------------------
  # KMS encryption
  # Per-resource key takes precedence; falls back to module-level key.
  # ---------------------------------------------------------------------------
  model_kms_key_id  = coalesce(each.value.model_kms_key_id, var.kms_key_arn)
  volume_kms_key_id = coalesce(each.value.volume_kms_key_id, var.volume_kms_key_arn)

  # ---------------------------------------------------------------------------
  # Input data configuration
  # ---------------------------------------------------------------------------
  input_data_config {
    # Entity types the recognizer should learn (one block per type)
    dynamic "entity_types" {
      for_each = each.value.entity_types

      content {
        type = entity_types.value.type
      }
    }

    # Training source: entity list (CSV of text/entity-type pairs)
    dynamic "entity_list" {
      for_each = each.value.entity_list != null ? [each.value.entity_list] : []

      content {
        s3_uri = entity_list.value.s3_uri
      }
    }

    # Training source: annotation files (augmented manifests / CSV annotations)
    dynamic "annotations" {
      for_each = each.value.annotations != null ? [each.value.annotations] : []

      content {
        s3_uri      = annotations.value.s3_uri
        test_s3_uri = annotations.value.test_s3_uri
      }
    }

    # Training source: raw documents
    dynamic "documents" {
      for_each = each.value.documents != null ? [each.value.documents] : []

      content {
        s3_uri       = documents.value.s3_uri
        test_s3_uri  = documents.value.test_s3_uri
        input_format = documents.value.input_format
      }
    }
  }

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
