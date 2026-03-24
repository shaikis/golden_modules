# ---------------------------------------------------------------------------
# Primary KMS Keys
# ---------------------------------------------------------------------------
resource "aws_kms_key" "this" {
  for_each = var.keys

  description              = coalesce(each.value.description, "KMS key for ${each.key} — managed by Terraform")
  key_usage                = each.value.key_usage
  customer_master_key_spec = each.value.customer_master_key_spec
  # Rotation is only valid for symmetric ENCRYPT_DECRYPT keys
  enable_key_rotation     = each.value.key_usage == "ENCRYPT_DECRYPT" && each.value.customer_master_key_spec == "SYMMETRIC_DEFAULT" ? each.value.enable_key_rotation : false
  rotation_period_in_days = each.value.key_usage == "ENCRYPT_DECRYPT" && each.value.customer_master_key_spec == "SYMMETRIC_DEFAULT" && each.value.enable_key_rotation ? each.value.rotation_period_in_days : null
  deletion_window_in_days = each.value.deletion_window_in_days
  is_enabled              = each.value.is_enabled
  multi_region            = each.value.multi_region
  policy                  = data.aws_iam_policy_document.merged[each.key].json

  tags = merge(
    {
      Name      = "${var.name_prefix}-${each.key}"
      ManagedBy = "terraform"
      Module    = "tf-aws-kms"
    },
    var.tags,
    each.value.tags,
  )
}

# ---------------------------------------------------------------------------
# Primary Aliases  (auto-generated + additional)
# ---------------------------------------------------------------------------

# One canonical alias per key: alias/<name_prefix>/<key_name>
resource "aws_kms_alias" "primary" {
  for_each = var.keys

  name          = "alias/${var.name_prefix}/${each.key}"
  target_key_id = aws_kms_key.this[each.key].key_id
}

# Additional custom aliases declared per key
locals {
  # Flatten additional_aliases into a map keyed by "<key_name>|<alias_string>"
  additional_alias_map = merge([
    for key_name, key_cfg in var.keys : {
      for alias_str in key_cfg.additional_aliases :
      "${key_name}|${alias_str}" => {
        key_name   = key_name
        alias_name = alias_str
      }
    }
  ]...)
}

resource "aws_kms_alias" "additional" {
  for_each = local.additional_alias_map

  name          = "alias/${each.value.alias_name}"
  target_key_id = aws_kms_key.this[each.value.key_name].key_id
}

# ---------------------------------------------------------------------------
# Multi-region Replica Keys
# ---------------------------------------------------------------------------
resource "aws_kms_replica_key" "this" {
  for_each = var.replica_keys

  primary_key_arn         = each.value.primary_key_arn
  description             = coalesce(each.value.description, "Replica KMS key for ${each.key} — managed by Terraform")
  deletion_window_in_days = each.value.deletion_window_in_days
  enabled                 = each.value.enabled
  policy                  = data.aws_iam_policy_document.replica_merged[each.key].json

  tags = merge(
    {
      Name      = "${var.name_prefix}-${each.key}-replica"
      ManagedBy = "terraform"
      Module    = "tf-aws-kms"
    },
    var.tags,
    each.value.tags,
  )
}
