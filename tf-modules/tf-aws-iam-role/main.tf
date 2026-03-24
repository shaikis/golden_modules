data "aws_iam_policy_document" "trust" {
  count = var.custom_trust_policy == "" ? 1 : 0

  dynamic "statement" {
    for_each = length(var.trusted_role_arns) > 0 || length(var.trusted_role_services) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = var.trusted_role_actions

      dynamic "principals" {
        for_each = length(var.trusted_role_arns) > 0 ? [1] : []
        content {
          type        = "AWS"
          identifiers = var.trusted_role_arns
        }
      }

      dynamic "principals" {
        for_each = length(var.trusted_role_services) > 0 ? [1] : []
        content {
          type        = "Service"
          identifiers = var.trusted_role_services
        }
      }

      dynamic "condition" {
        for_each = var.assume_role_conditions
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_role" "this" {
  name                  = local.name
  description           = var.description
  assume_role_policy    = var.custom_trust_policy != "" ? var.custom_trust_policy : data.aws_iam_policy_document.trust[0].json
  max_session_duration  = var.max_session_duration
  force_detach_policies = var.force_detach_policies
  permissions_boundary  = var.permissions_boundary

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"]]
  }
}

# Managed policy attachments
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# Inline policies
resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0

  name = local.name
  role = aws_iam_role.this.name
  tags = local.tags
}
