# ── CloudWatch Log Groups (auto-created per state machine when logging enabled) ─

resource "aws_cloudwatch_log_group" "sfn" {
  for_each = {
    for k, v in var.state_machines :
    k => v
    if v.logging != null && try(v.logging.log_group_name, null) == null
  }

  name              = "/aws/states/${var.name_prefix}${each.key}"
  retention_in_days = 90
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, try(each.value.tags, {}))
}

# ── State Machines ────────────────────────────────────────────────────────────

resource "aws_sfn_state_machine" "this" {
  for_each = var.state_machines

  name     = "${var.name_prefix}${each.key}"
  type     = each.value.type
  role_arn = coalesce(each.value.role_arn, var.role_arn, try(aws_iam_role.sfn[0].arn, null))

  definition          = each.value.definition
  publish             = each.value.publish
  version_description = each.value.publish ? each.value.version_description : null

  dynamic "logging_configuration" {
    for_each = each.value.logging != null ? [each.value.logging] : []
    content {
      log_destination = each.value.logging.log_group_name != null ? (
        "${each.value.logging.log_group_name}:*"
        ) : (
        "${aws_cloudwatch_log_group.sfn[each.key].arn}:*"
      )
      include_execution_data = logging_configuration.value.include_execution_data
      level                  = logging_configuration.value.level
    }
  }

  dynamic "tracing_configuration" {
    for_each = each.value.tracing_enabled ? [1] : []
    content {
      enabled = true
    }
  }

  tags = merge(var.tags, each.value.tags)
}
