output "event_bus_arns" {
  description = "Custom event bus ARNs."
  value       = module.eventbridge.event_bus_arns
}

output "rule_arns" {
  description = "EventBridge rule ARNs."
  value       = module.eventbridge.rule_arns
}

output "rule_names" {
  description = "EventBridge rule names."
  value       = module.eventbridge.rule_names
}

output "archive_arns" {
  description = "Event archive ARNs."
  value       = module.eventbridge.archive_arns
}

output "pipe_arns" {
  description = "EventBridge Pipe ARNs."
  value       = module.eventbridge.pipe_arns
}

output "schema_registry_arns" {
  description = "Schema registry ARNs."
  value       = module.eventbridge.schema_registry_arns
}

output "eventbridge_role_arn" {
  description = "EventBridge invocation IAM role ARN."
  value       = module.eventbridge.eventbridge_role_arn
}

output "pipes_role_arn" {
  description = "EventBridge Pipes IAM role ARN."
  value       = module.eventbridge.pipes_role_arn
}

output "alarm_arns" {
  description = "CloudWatch alarm ARNs."
  value       = module.eventbridge.alarm_arns
}

output "api_destination_arns" {
  description = "API destination ARNs."
  value       = module.eventbridge.api_destination_arns
}

output "aws_region" {
  description = "AWS region."
  value       = module.eventbridge.aws_region
}

output "aws_account_id" {
  description = "AWS account ID."
  value       = module.eventbridge.aws_account_id
}
