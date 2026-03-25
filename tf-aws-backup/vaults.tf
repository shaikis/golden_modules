############################################
# VAULTS
############################################
resource "aws_backup_vault" "this" {
  for_each = var.vaults

  name        = "${local.name_prefix}-${each.key}"
  kms_key_arn = each.value.kms_key_arn
  tags        = merge(local.common_tags, each.value.tags)
}

############################################
# VAULT POLICY
############################################
resource "aws_backup_vault_policy" "this" {
  for_each = {
    for k, v in var.vaults : k => v if v.policy != null
  }

  backup_vault_name = aws_backup_vault.this[each.key].name
  policy            = each.value.policy
}

############################################
# VAULT LOCK
############################################
resource "aws_backup_vault_lock_configuration" "this" {
  for_each = {
    for k, v in var.vaults : k => v if v.enable_vault_lock
  }

  backup_vault_name = aws_backup_vault.this[each.key].name

  changeable_for_days = each.value.vault_lock_changeable_for_days
  min_retention_days  = each.value.vault_lock_min_retention_days
  max_retention_days  = each.value.vault_lock_max_retention_days
}

############################################
# VAULT NOTIFICATIONS
# Priority: per-vault sns_topic_arn > module-level effective_sns_topic_arn
############################################
resource "aws_backup_vault_notifications" "this" {
  for_each = {
    for k, v in var.vaults : k => v
    if v.sns_topic_arn != null || local.effective_sns_topic_arn != null
  }

  backup_vault_name   = aws_backup_vault.this[each.key].name
  sns_topic_arn       = coalesce(each.value.sns_topic_arn, local.effective_sns_topic_arn)
  backup_vault_events = each.value.notification_events
}
