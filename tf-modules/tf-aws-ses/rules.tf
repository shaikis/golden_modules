# ── Receipt Rule Sets ──────────────────────────────────────────────────────────

resource "aws_ses_receipt_rule_set" "this" {
  for_each = var.create_receipt_rules ? var.rule_sets : {}

  rule_set_name = each.key
}

resource "aws_ses_active_receipt_rule_set" "this" {
  for_each = var.create_receipt_rules ? {
    for k, v in var.rule_sets : k => v
    if v.active
  } : {}

  rule_set_name = aws_ses_receipt_rule_set.this[each.key].rule_set_name
}

# ── Receipt Rules ──────────────────────────────────────────────────────────────

resource "aws_ses_receipt_rule" "this" {
  for_each = var.create_receipt_rules ? var.receipt_rules : {}

  name          = each.key
  rule_set_name = each.value.rule_set_name
  recipients    = each.value.recipients
  enabled       = each.value.enabled
  scan_enabled  = each.value.scan_enabled
  tls_policy    = each.value.tls_policy
  after         = each.value.after

  dynamic "s3_action" {
    for_each = each.value.s3_actions
    content {
      bucket_name = s3_action.value.bucket_name
      key_prefix  = s3_action.value.key_prefix
      kms_key_arn = s3_action.value.kms_key_arn
      position    = s3_action.value.position
    }
  }

  dynamic "sns_action" {
    for_each = each.value.sns_actions
    content {
      topic_arn = sns_action.value.topic_arn
      position  = sns_action.value.position
    }
  }

  dynamic "lambda_action" {
    for_each = each.value.lambda_actions
    content {
      function_arn    = lambda_action.value.function_arn
      invocation_type = lambda_action.value.invocation_type
      position        = lambda_action.value.position
    }
  }

  dynamic "bounce_action" {
    for_each = each.value.bounce_actions
    content {
      message         = bounce_action.value.message
      sender          = bounce_action.value.sender
      smtp_reply_code = bounce_action.value.smtp_reply_code
      status_code     = bounce_action.value.status_code
      topic_arn       = bounce_action.value.topic_arn
      position        = bounce_action.value.position
    }
  }

  dynamic "stop_action" {
    for_each = each.value.stop_actions
    content {
      scope     = stop_action.value.scope
      topic_arn = stop_action.value.topic_arn
      position  = stop_action.value.position
    }
  }

  dynamic "workmail_action" {
    for_each = each.value.workmail_actions
    content {
      organization_arn = workmail_action.value.organization_arn
      topic_arn        = workmail_action.value.topic_arn
      position         = workmail_action.value.position
    }
  }

  dynamic "add_header_action" {
    for_each = each.value.add_header_actions
    content {
      header_name  = add_header_action.value.header_name
      header_value = add_header_action.value.header_value
      position     = add_header_action.value.position
    }
  }

  depends_on = [aws_ses_receipt_rule_set.this]
}
