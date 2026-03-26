# ──────────────────────────────────────────────────────────────────────────────
# SNS Topics — Async Textract job completion notifications
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_sns_topic" "textract" {
  for_each = var.create_sns_topics ? var.sns_topics : {}

  name              = "${local.name_prefix}textract-${each.key}"
  display_name      = each.value.display_name
  kms_master_key_id = coalesce(each.value.kms_master_key_id, var.kms_key_arn)

  tags = merge(local.tags, each.value.tags)
}

# ── SNS topic policy allowing Textract service to publish ─────────────────────

data "aws_iam_policy_document" "sns_textract" {
  for_each = var.create_sns_topics ? var.sns_topics : {}

  statement {
    sid    = "AllowTextractPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["textract.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.textract[each.key].arn]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:${data.aws_partition.current.partition}:textract:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      ]
    }
  }
}

resource "aws_sns_topic_policy" "textract" {
  for_each = var.create_sns_topics ? var.sns_topics : {}

  arn    = aws_sns_topic.textract[each.key].arn
  policy = data.aws_iam_policy_document.sns_textract[each.key].json
}
