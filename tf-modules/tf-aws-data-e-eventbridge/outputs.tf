output "event_bus_arns" {
  description = "Map of custom event bus ARNs keyed by bus name."
  value       = { for k, v in aws_cloudwatch_event_bus.this : k => v.arn }
}

output "event_bus_names" {
  description = "Map of custom event bus names keyed by bus key."
  value       = { for k, v in aws_cloudwatch_event_bus.this : k => v.name }
}

output "rule_arns" {
  description = "Map of EventBridge rule ARNs keyed by rule name."
  value       = { for k, v in aws_cloudwatch_event_rule.this : k => v.arn }
}

output "rule_names" {
  description = "Map of EventBridge rule names keyed by rule key."
  value       = { for k, v in aws_cloudwatch_event_rule.this : k => v.name }
}

output "archive_arns" {
  description = "Map of event archive ARNs keyed by archive name."
  value       = { for k, v in aws_cloudwatch_event_archive.this : k => v.arn }
}

output "pipe_arns" {
  description = "Map of EventBridge Pipe ARNs keyed by pipe name."
  value       = { for k, v in aws_pipes_pipe.this : k => v.arn }
}

output "schema_registry_arns" {
  description = "Map of schema registry ARNs keyed by registry name."
  value       = { for k, v in aws_schemas_registry.this : k => v.arn }
}

output "schema_arns" {
  description = "Map of schema ARNs keyed by schema name."
  value       = { for k, v in aws_schemas_schema.this : k => v.arn }
}

output "eventbridge_role_arn" {
  description = "ARN of the EventBridge invocation IAM role."
  value       = var.create_iam_role ? try(aws_iam_role.eventbridge[0].arn, null) : var.role_arn
}

output "eventbridge_role_name" {
  description = "Name of the EventBridge invocation IAM role."
  value       = var.create_iam_role ? try(aws_iam_role.eventbridge[0].name, null) : null
}

output "pipes_role_arn" {
  description = "ARN of the EventBridge Pipes execution IAM role."
  value       = var.create_iam_role && var.create_pipes ? try(aws_iam_role.eventbridge_pipes[0].arn, null) : null
}

output "alarm_arns" {
  description = "Map of CloudWatch alarm ARNs for failed invocations, keyed by rule name."
  value       = { for k, v in aws_cloudwatch_metric_alarm.failed_invocations : k => v.arn }
}

output "api_connection_arns" {
  description = "Map of API connection ARNs keyed by connection name."
  value       = { for k, v in aws_cloudwatch_event_connection.this : k => v.arn }
}

output "api_destination_arns" {
  description = "Map of API destination ARNs keyed by destination name."
  value       = { for k, v in aws_cloudwatch_event_api_destination.this : k => v.arn }
}

output "aws_region" {
  description = "AWS region where EventBridge resources are deployed."
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID in which EventBridge resources are deployed."
  value       = data.aws_caller_identity.current.account_id
}
