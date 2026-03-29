output "config_rule_name" {
  description = "Name of the AWS Config required tags rule."
  value       = aws_config_config_rule.required_tags.name
}

output "config_rule_arn" {
  description = "ARN of the AWS Config required tags rule."
  value       = aws_config_config_rule.required_tags.arn
}

output "required_tags" {
  description = "Required tags enforced by the module."
  value       = var.required_tags
}

output "sns_topic_arn" {
  description = "SNS topic ARN used for compliance notifications."
  value       = local.effective_sns_topic_arn
}

output "config_recorder_name" {
  description = "AWS Config recorder name when created by this module."
  value       = try(aws_config_configuration_recorder.this[0].name, null)
}

output "config_delivery_channel_name" {
  description = "AWS Config delivery channel name when created by this module."
  value       = try(aws_config_delivery_channel.this[0].name, null)
}

output "eventbridge_rule_name" {
  description = "EventBridge rule name used for compliance notifications."
  value       = try(aws_cloudwatch_event_rule.config_compliance[0].name, null)
}
