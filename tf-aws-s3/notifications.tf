# ---------------------------------------------------------------------------
# Notifications
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_notification" "this" {
  count  = var.notifications != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "lambda_function" {
    for_each = try(var.notifications.lambda_functions, [])
    content {
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.filter_prefix
      filter_suffix       = lambda_function.value.filter_suffix
    }
  }

  dynamic "queue" {
    for_each = try(var.notifications.sqs_queues, [])
    content {
      queue_arn     = queue.value.queue_arn
      events        = queue.value.events
      filter_prefix = queue.value.filter_prefix
      filter_suffix = queue.value.filter_suffix
    }
  }

  dynamic "topic" {
    for_each = try(var.notifications.sns_topics, [])
    content {
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = topic.value.filter_prefix
      filter_suffix = topic.value.filter_suffix
    }
  }
}
