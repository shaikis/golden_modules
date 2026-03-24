# ---------------------------------------------------------------------------
# IAM Roles — map-driven, supports service / AWS / federated trust principals
# ---------------------------------------------------------------------------

locals {
  # Resolve the final role name: explicit override OR auto-generated
  role_names = {
    for k, v in var.roles :
    k => coalesce(v.name, "${var.name_prefix}-${k}")
  }
}

# One trust-policy document per role
data "aws_iam_policy_document" "trust" {
  for_each = var.roles

  # --- Service principal trust (e.g. glue.amazonaws.com) -------------------
  dynamic "statement" {
    for_each = length(each.value.service_principals) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "Service"
        identifiers = each.value.service_principals
      }
    }
  }

  # --- AWS principal trust (IAM roles / accounts / users) ------------------
  dynamic "statement" {
    for_each = length(each.value.aws_principals) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "AWS"
        identifiers = each.value.aws_principals
      }
    }
  }

  # --- Federated (OIDC / SAML) trust ----------------------------------------
  dynamic "statement" {
    for_each = length(each.value.federated_principals) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRoleWithWebIdentity"]

      principals {
        type        = "Federated"
        identifiers = each.value.federated_principals
      }

      dynamic "condition" {
        for_each = each.value.oidc_conditions
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# aws_iam_role — one per map entry
# ---------------------------------------------------------------------------

resource "aws_iam_role" "this" {
  for_each = var.roles

  name                  = local.role_names[each.key]
  description           = each.value.description
  path                  = each.value.path
  max_session_duration  = each.value.max_session_duration
  force_detach_policies = each.value.force_detach_policies
  permissions_boundary  = each.value.permission_boundary_arn

  assume_role_policy = data.aws_iam_policy_document.trust[each.key].json

  tags = merge(var.tags, each.value.tags, {
    Name      = local.role_names[each.key]
    ManagedBy = "terraform"
  })

  lifecycle {
    ignore_changes = [tags["CreatedDate"]]
  }
}

# ---------------------------------------------------------------------------
# Managed policy attachments
# For each role, for each managed_policy_arn, create one attachment.
# Key format: "<role_key>||<policy_arn>"
# ---------------------------------------------------------------------------

locals {
  role_managed_policy_pairs = merge([
    for role_key, role_cfg in var.roles : {
      for arn in role_cfg.managed_policy_arns :
      "${role_key}||${arn}" => {
        role_key   = role_key
        policy_arn = arn
      }
    }
  ]...)
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = local.role_managed_policy_pairs

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.policy_arn
}

# ---------------------------------------------------------------------------
# Inline policies
# Key format: "<role_key>||<policy_name>"
# ---------------------------------------------------------------------------

locals {
  role_inline_policy_pairs = merge([
    for role_key, role_cfg in var.roles : {
      for policy_name, policy_json in role_cfg.inline_policies :
      "${role_key}||${policy_name}" => {
        role_key    = role_key
        policy_name = policy_name
        policy_json = policy_json
      }
    }
  ]...)
}

resource "aws_iam_role_policy" "inline" {
  for_each = local.role_inline_policy_pairs

  name   = each.value.policy_name
  role   = aws_iam_role.this[each.value.role_key].id
  policy = each.value.policy_json
}
