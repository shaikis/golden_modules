# ---------------------------------------------------------------------------
# Collections
# ---------------------------------------------------------------------------

output "collection_ids" {
  description = "Map of collection key → collection_id for all created face collections."
  value = {
    for k, v in aws_rekognition_collection.this : k => v.collection_id
  }
}

output "collection_arns" {
  description = "Map of collection key → ARN for all created face collections."
  value = {
    for k, v in aws_rekognition_collection.this : k => v.arn
  }
}

# ---------------------------------------------------------------------------
# Stream Processors
# ---------------------------------------------------------------------------

output "stream_processor_arns" {
  description = "Map of stream processor key → ARN for all created stream processors."
  value = {
    for k, v in aws_rekognition_stream_processor.this : k => v.arn
  }
}

output "stream_processor_names" {
  description = "Map of stream processor key → resource name."
  value = {
    for k, v in aws_rekognition_stream_processor.this : k => v.name
  }
}

# ---------------------------------------------------------------------------
# Custom Labels Projects
# ---------------------------------------------------------------------------

output "custom_labels_project_arns" {
  description = "Map of project key → ARN for all created Custom Labels projects."
  value = {
    for k, v in aws_rekognition_project.this : k => v.arn
  }
}

output "custom_labels_project_names" {
  description = "Map of project key → name for all created Custom Labels projects."
  value = {
    for k, v in aws_rekognition_project.this : k => v.name
  }
}

# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------

output "iam_role_arn" {
  description = "ARN of the IAM role used by Rekognition resources (auto-created or BYO)."
  value       = local.role_arn
}

output "iam_role_name" {
  description = "Name of the auto-created IAM role, or null when BYO."
  value       = var.create_iam_role ? aws_iam_role.rekognition[0].name : null
}

# ---------------------------------------------------------------------------
# CloudWatch Alarms
# ---------------------------------------------------------------------------

output "alarm_arns" {
  description = "Map of alarm key → ARN for all created CloudWatch alarms."
  value = merge(
    { for k, v in aws_cloudwatch_metric_alarm.stream_processor_errors : "errors-${k}" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.stream_processor_throttles : "throttles-${k}" => v.arn },
  )
}

# ---------------------------------------------------------------------------
# Contextual / convenience
# ---------------------------------------------------------------------------

output "aws_account_id" {
  description = "AWS account ID in which the module is deployed."
  value       = local.account_id
}

output "aws_region" {
  description = "AWS region in which the module is deployed."
  value       = local.region
}
