data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "config_assume_role" {
  count = var.create_config_recorder && var.create_config_role ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "config" {
  count = var.create_config_recorder && var.create_config_role ? 1 : 0

  name               = "${local.name_prefix}-config"
  assume_role_policy = data.aws_iam_policy_document.config_assume_role[0].json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "config_managed" {
  count = var.create_config_recorder && var.create_config_role ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "this" {
  count = var.create_config_recorder ? 1 : 0

  name     = local.name_prefix
  role_arn = local.effective_config_role_arn

  recording_group {
    all_supported                 = length(var.resource_types_scope) == 0
    include_global_resource_types = var.include_global_resource_types
    resource_types                = length(var.resource_types_scope) == 0 ? null : var.resource_types_scope
  }
}

resource "aws_config_delivery_channel" "this" {
  count = var.create_config_recorder ? 1 : 0

  name           = local.name_prefix
  s3_bucket_name = var.config_s3_bucket_name
  sns_topic_arn  = local.effective_sns_topic_arn

  snapshot_delivery_properties {
    delivery_frequency = var.config_snapshot_delivery_frequency
  }

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  count = var.create_config_recorder ? 1 : 0

  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

resource "aws_sns_topic" "this" {
  count = var.create_sns_topic && var.sns_topic_arn == null ? 1 : 0

  name              = "${local.name_prefix}-tag-governance"
  kms_master_key_id = var.sns_kms_key_id
  tags              = local.common_tags
}

data "aws_iam_policy_document" "sns_topic" {
  count = local.effective_sns_topic_arn != null && var.create_eventbridge_notifications ? 1 : 0

  statement {
    sid    = "AllowEventBridgePublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sns:Publish"]
    resources = [local.effective_sns_topic_arn]
  }
}

resource "aws_sns_topic_policy" "this" {
  count = var.create_sns_topic && var.sns_topic_arn == null && var.create_eventbridge_notifications ? 1 : 0

  arn    = aws_sns_topic.this[0].arn
  policy = data.aws_iam_policy_document.sns_topic[0].json
}

resource "aws_config_config_rule" "required_tags" {
  name = "${local.name_prefix}-required-tags"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode(local.required_tags_input_parameters)

  dynamic "scope" {
    for_each = length(var.resource_types_scope) > 0 ? [1] : []
    content {
      compliance_resource_types = var.resource_types_scope
    }
  }

  maximum_execution_frequency = var.tag_rule_maximum_execution_frequency

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_cloudwatch_event_rule" "config_compliance" {
  count = local.effective_sns_topic_arn != null && var.create_eventbridge_notifications ? 1 : 0

  name        = "${local.name_prefix}-config-compliance"
  description = "Routes AWS Config required tag compliance changes to SNS."

  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      configRuleName = [aws_config_config_rule.required_tags.name]
    }
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "sns" {
  count = local.effective_sns_topic_arn != null && var.create_eventbridge_notifications ? 1 : 0

  rule      = aws_cloudwatch_event_rule.config_compliance[0].name
  target_id = "sns"
  arn       = local.effective_sns_topic_arn
}
