# ──────────────────────────────────────────────────────────────────────────────
# SQS Queues — Receive and process Textract async job results
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_sqs_queue" "textract" {
  for_each = var.create_sqs_queues ? var.sqs_queues : {}

  name                       = "${local.name_prefix}textract-${each.key}"
  visibility_timeout_seconds = each.value.visibility_timeout_seconds
  message_retention_seconds  = each.value.message_retention_seconds
  kms_master_key_id          = coalesce(each.value.kms_master_key_id, var.kms_key_arn)

  # Wire up DLQ redrive policy when a DLQ is configured for this queue
  dynamic "redrive_policy" {
    for_each = each.value.create_dlq ? [1] : []
    content {
      deadLetterTargetArn = aws_sqs_queue.textract_dlq[each.key].arn
      maxReceiveCount     = 5
    }
  }

  tags = merge(local.tags, each.value.tags)
}

# ── Dead Letter Queues ────────────────────────────────────────────────────────

resource "aws_sqs_queue" "textract_dlq" {
  for_each = {
    for k, v in(var.create_sqs_queues ? var.sqs_queues : {}) : k => v
    if v.create_dlq
  }

  name                      = "${local.name_prefix}textract-${each.key}-dlq"
  message_retention_seconds = each.value.message_retention_seconds
  kms_master_key_id         = coalesce(each.value.kms_master_key_id, var.kms_key_arn)

  tags = merge(local.tags, each.value.tags)
}

# ── SQS Queue Policy — allow SNS topics to deliver messages ──────────────────

data "aws_iam_policy_document" "sqs_textract" {
  for_each = var.create_sqs_queues ? var.sqs_queues : {}

  statement {
    sid    = "AllowSNSDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.textract[each.key].arn]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:${data.aws_partition.current.partition}:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      ]
    }
  }
}

resource "aws_sqs_queue_policy" "textract" {
  for_each = var.create_sqs_queues ? var.sqs_queues : {}

  queue_url = aws_sqs_queue.textract[each.key].id
  policy    = data.aws_iam_policy_document.sqs_textract[each.key].json
}
