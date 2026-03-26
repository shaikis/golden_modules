# ──────────────────────────────────────────────────────────────────────────────
# IAM Outputs
# ──────────────────────────────────────────────────────────────────────────────

output "iam_role_arn" {
  description = "ARN of the IAM role used for Textract API access. Either auto-created or the BYO role_arn."
  value       = local.role_arn
}

output "iam_role_name" {
  description = "Name of the auto-created IAM caller role for Textract. Empty string when create_iam_role = false."
  value       = var.create_iam_role ? aws_iam_role.textract[0].name : ""
}

output "iam_service_role_arn" {
  description = "ARN of the IAM role assumed by the Textract service to publish async job results to SNS. Empty string when create_iam_role = false."
  value       = var.create_iam_role ? aws_iam_role.textract_service[0].arn : ""
}

output "iam_service_role_name" {
  description = "Name of the IAM role assumed by the Textract service to publish async job results to SNS. Empty string when create_iam_role = false."
  value       = var.create_iam_role ? aws_iam_role.textract_service[0].name : ""
}

# ──────────────────────────────────────────────────────────────────────────────
# SNS Outputs
# ──────────────────────────────────────────────────────────────────────────────

output "sns_topic_arns" {
  description = "Map of SNS topic key to ARN for all created Textract notification topics."
  value       = { for k, v in aws_sns_topic.textract : k => v.arn }
}

output "sns_topic_names" {
  description = "Map of SNS topic key to name for all created Textract notification topics."
  value       = { for k, v in aws_sns_topic.textract : k => v.name }
}

# ──────────────────────────────────────────────────────────────────────────────
# SQS Outputs
# ──────────────────────────────────────────────────────────────────────────────

output "sqs_queue_urls" {
  description = "Map of SQS queue key to URL for all created Textract result queues."
  value       = { for k, v in aws_sqs_queue.textract : k => v.id }
}

output "sqs_queue_arns" {
  description = "Map of SQS queue key to ARN for all created Textract result queues."
  value       = { for k, v in aws_sqs_queue.textract : k => v.arn }
}

output "sqs_queue_names" {
  description = "Map of SQS queue key to name for all created Textract result queues."
  value       = { for k, v in aws_sqs_queue.textract : k => v.name }
}

output "sqs_dlq_arns" {
  description = "Map of SQS queue key to DLQ ARN. Only populated for queues where create_dlq = true."
  value       = { for k, v in aws_sqs_queue.textract_dlq : k => v.arn }
}

output "sqs_dlq_urls" {
  description = "Map of SQS queue key to DLQ URL. Only populated for queues where create_dlq = true."
  value       = { for k, v in aws_sqs_queue.textract_dlq : k => v.id }
}

# ──────────────────────────────────────────────────────────────────────────────
# Alarm Outputs
# ──────────────────────────────────────────────────────────────────────────────

output "cloudwatch_alarm_arns" {
  description = "Map of alarm name to ARN for all created CloudWatch alarms."
  value = merge(
    { for k, v in aws_cloudwatch_metric_alarm.sqs_queue_depth : v.alarm_name => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.sqs_dlq_depth : v.alarm_name => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.sqs_oldest_message_age : v.alarm_name => v.arn },
  )
}
