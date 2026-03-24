output "rule_arns" {
  description = "EventBridge rule ARNs."
  value       = module.eventbridge.rule_arns
}

output "eventbridge_role_arn" {
  description = "ARN of the auto-created EventBridge invocation role."
  value       = module.eventbridge.eventbridge_role_arn
}
