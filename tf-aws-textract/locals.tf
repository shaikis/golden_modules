locals {
  name_prefix = var.name_prefix != "" ? "${var.name_prefix}-" : ""

  tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "tf-aws-textract"
  })

  # Resolve the effective role ARN: auto-created or BYO
  role_arn = var.create_iam_role ? aws_iam_role.textract[0].arn : var.role_arn

  # Collect all created SNS topic ARNs for inline policy attachment
  sns_topic_arns = var.create_sns_topics ? [
    for k, v in aws_sns_topic.textract : v.arn
  ] : []

  # Collect all created SQS queue ARNs for inline policy attachment
  sqs_queue_arns = var.create_sqs_queues ? [
    for k, v in aws_sqs_queue.textract : v.arn
  ] : []
}
