output "state_machine_arns" {
  description = "Map of state machine name => ARN."
  value       = module.sfn.state_machine_arns
}

output "state_machine_names" {
  description = "Map of state machine name => resource name."
  value       = module.sfn.state_machine_names
}

output "activity_arns" {
  description = "Map of activity name => ARN."
  value       = module.sfn.activity_arns
}

output "sfn_role_arn" {
  description = "Step Functions execution IAM role ARN."
  value       = module.sfn.sfn_role_arn
}

output "alarm_arns" {
  description = "Map of alarm name => ARN."
  value       = module.sfn.alarm_arns
}

output "log_group_arns" {
  description = "Map of state machine => CloudWatch Log Group ARN."
  value       = module.sfn.log_group_arns
}
