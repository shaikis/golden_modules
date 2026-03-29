############################################
# BACKUP PLANS
############################################
resource "aws_backup_plan" "this" {
  for_each = var.plans

  name = "${local.name_prefix}-${each.key}"

  dynamic "rule" {
    for_each = each.value.rules

    content {
      rule_name = rule.value.rule_name

      target_vault_name = coalesce(
        try(aws_backup_vault.this[rule.value.vault_key].name, null),
        rule.value.target_vault_name
      )

      schedule                     = rule.value.schedule
      schedule_expression_timezone = rule.value.schedule_expression_timezone
      start_window                 = rule.value.start_window
      completion_window            = rule.value.completion_window

      enable_continuous_backup = rule.value.enable_continuous_backup
      recovery_point_tags      = rule.value.recovery_point_tags

      dynamic "lifecycle" {
        for_each = rule.value.lifecycle != null ? [rule.value.lifecycle] : []
        content {
          cold_storage_after = lifecycle.value.cold_storage_after
          delete_after       = lifecycle.value.delete_after
        }
      }

      dynamic "copy_action" {
        for_each = rule.value.copy_actions
        content {
          destination_vault_arn = coalesce(
            try(aws_backup_vault.dr[copy_action.value.destination_vault_key].arn, null),
            copy_action.value.destination_vault_arn
          )

          dynamic "lifecycle" {
            for_each = copy_action.value.lifecycle != null ? [copy_action.value.lifecycle] : []
            content {
              cold_storage_after = lifecycle.value.cold_storage_after
              delete_after       = lifecycle.value.delete_after
            }
          }
        }
      }
    }
  }

  dynamic "advanced_backup_setting" {
    for_each = each.value.advanced_backup_settings
    content {
      resource_type  = advanced_backup_setting.value.resource_type
      backup_options = advanced_backup_setting.value.backup_options
    }
  }

  tags = merge(local.common_tags, each.value.tags)
}
