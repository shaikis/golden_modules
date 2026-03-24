output "state_machine_arns" {
  description = "Map of state machine key => ARN."
  value       = { for k, v in aws_sfn_state_machine.this : k => v.arn }
}

output "state_machine_names" {
  description = "Map of state machine key => name."
  value       = { for k, v in aws_sfn_state_machine.this : k => v.name }
}

output "state_machine_creation_dates" {
  description = "Map of state machine key => creation date."
  value       = { for k, v in aws_sfn_state_machine.this : k => v.creation_date }
}

output "state_machine_statuses" {
  description = "Map of state machine key => status."
  value       = { for k, v in aws_sfn_state_machine.this : k => v.status }
}

output "activity_arns" {
  description = "Map of activity key => ARN. Empty when create_activities = false."
  value       = { for k, v in aws_sfn_activity.this : k => v.id }
}

output "sfn_role_arn" {
  description = "ARN of the Step Functions execution IAM role created by this module. Null when create_iam_role = false."
  value       = var.create_iam_role ? aws_iam_role.sfn[0].arn : null
}

output "sfn_role_name" {
  description = "Name of the Step Functions execution IAM role. Null when create_iam_role = false."
  value       = var.create_iam_role ? aws_iam_role.sfn[0].name : null
}

output "alarm_arns" {
  description = "Map of alarm name => ARN. Empty when create_alarms = false."
  value = merge(
    { for k, v in aws_cloudwatch_metric_alarm.sfn_executions_failed : "${k}-executions-failed" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.sfn_executions_timed_out : "${k}-executions-timed-out" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.sfn_executions_aborted : "${k}-executions-aborted" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.sfn_execution_throttled : "${k}-execution-throttled" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.sfn_execution_time : "${k}-execution-time-p99" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.sfn_express_failed_rate : "${k}-express-failed-rate" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.sfn_express_timeout_rate : "${k}-express-timeout-rate" => v.arn },
  )
}

output "log_group_arns" {
  description = "Map of state machine key => auto-created CloudWatch Log Group ARN."
  value       = { for k, v in aws_cloudwatch_log_group.sfn : k => v.arn }
}
