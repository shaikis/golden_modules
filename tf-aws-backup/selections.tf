############################################
# SELECTIONS
############################################
resource "aws_backup_selection" "this" {
  for_each = var.selections

  name    = "${local.name_prefix}-${each.key}"
  plan_id = aws_backup_plan.this[each.value.plan_key].id

  iam_role_arn = coalesce(
    each.value.iam_role_arn, # 1. per-selection override
    local.iam_role_arn       # 2. module-level (BYO or created)
  )

  resources     = each.value.resources
  not_resources = each.value.not_resources

  dynamic "selection_tag" {
    for_each = each.value.selection_tags
    content {
      type  = selection_tag.value.type
      key   = selection_tag.value.key
      value = selection_tag.value.value
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions != null ? [each.value.conditions] : []
    content {
      dynamic "string_equals" {
        for_each = condition.value.string_equals
        content {
          key   = string_equals.value.key
          value = string_equals.value.value
        }
      }

      dynamic "string_not_equals" {
        for_each = condition.value.string_not_equals
        content {
          key   = string_not_equals.value.key
          value = string_not_equals.value.value
        }
      }

      dynamic "string_like" {
        for_each = condition.value.string_like
        content {
          key   = string_like.value.key
          value = string_like.value.value
        }
      }

      dynamic "string_not_like" {
        for_each = condition.value.string_not_like
        content {
          key   = string_not_like.value.key
          value = string_not_like.value.value
        }
      }
    }
  }
}
