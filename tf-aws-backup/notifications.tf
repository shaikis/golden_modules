############################################
# SNS TOPIC (Module-Level)
# create_sns_topic = true  + sns_topic_arn = null → module creates new topic
# create_sns_topic = false + sns_topic_arn = ARN  → use existing topic (BYO)
# create_sns_topic = false + sns_topic_arn = null → no module-level notifications
############################################
resource "aws_sns_topic" "this" {
  count             = var.create_sns_topic && var.sns_topic_arn == null ? 1 : 0
  name              = "${local.name_prefix}-backup-notifications"
  kms_master_key_id = var.sns_kms_key_id
  tags              = local.common_tags
}

resource "aws_sns_topic_policy" "this" {
  count = var.create_sns_topic && var.sns_topic_arn == null ? 1 : 0
  arn   = aws_sns_topic.this[0].arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowBackupPublish"
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.this[0].arn
    }]
  })
}
