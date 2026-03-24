# ---------------------------------------------------------------------------
# Dead Letter Queue
# ---------------------------------------------------------------------------
resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name                              = local.dlq_name
  fifo_queue                        = var.fifo_queue
  content_based_deduplication       = var.fifo_queue && var.content_based_deduplication ? true : false
  message_retention_seconds         = var.dlq_message_retention_seconds
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_master_key_id != null ? var.kms_data_key_reuse_period_seconds : null

  tags = merge(local.tags, { Name = local.dlq_name, QueueType = "DLQ" })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

# ---------------------------------------------------------------------------
# Main Queue
# ---------------------------------------------------------------------------
resource "aws_sqs_queue" "this" {
  name                        = local.queue_name
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue && var.content_based_deduplication ? true : false
  deduplication_scope         = var.deduplication_scope
  fifo_throughput_limit       = var.fifo_throughput_limit
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  message_retention_seconds   = var.message_retention_seconds
  max_message_size            = var.max_message_size
  delay_seconds               = var.delay_seconds
  receive_wait_time_seconds   = var.receive_wait_time_seconds

  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_master_key_id != null ? var.kms_data_key_reuse_period_seconds : null

  redrive_policy = var.create_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.maxReceiveCount
  }) : null

  tags = merge(local.tags, { Name = local.queue_name })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

# ---------------------------------------------------------------------------
# Queue Policy
# ---------------------------------------------------------------------------
resource "aws_sqs_queue_policy" "this" {
  count     = var.queue_policy != "" ? 1 : 0
  queue_url = aws_sqs_queue.this.id
  policy    = var.queue_policy
}
