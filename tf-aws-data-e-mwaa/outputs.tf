output "environment_arns" {
  description = "Map of environment key => ARN."
  value       = { for k, v in aws_mwaa_environment.this : k => v.arn }
}

output "environment_names" {
  description = "Map of environment key => resource name."
  value       = { for k, v in aws_mwaa_environment.this : k => v.name }
}

output "webserver_urls" {
  description = "Map of environment key => Airflow webserver URL."
  value       = { for k, v in aws_mwaa_environment.this : k => v.webserver_url }
}

output "environment_statuses" {
  description = "Map of environment key => current status."
  value       = { for k, v in aws_mwaa_environment.this : k => v.status }
}

output "mwaa_role_arn" {
  description = "ARN of the MWAA execution IAM role created by this module. Null when create_iam_role = false."
  value       = var.create_iam_role ? aws_iam_role.mwaa[0].arn : null
}

output "mwaa_role_name" {
  description = "Name of the MWAA execution IAM role. Null when create_iam_role = false."
  value       = var.create_iam_role ? aws_iam_role.mwaa[0].name : null
}

output "alarm_arns" {
  description = "Map of alarm name => ARN. Empty when create_alarms = false."
  value = merge(
    { for k, v in aws_cloudwatch_metric_alarm.mwaa_queued_tasks : "${k}-queued-tasks" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.mwaa_running_tasks : "${k}-running-tasks" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.mwaa_scheduler_heartbeat : "${k}-scheduler-heartbeat" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.mwaa_tasks_pending : "${k}-tasks-pending" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.mwaa_worker_online : "${k}-worker-online-count" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.mwaa_dag_parse_time : "${k}-dag-parse-time" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.mwaa_dlq_size : "${k}-dead-letter-queue" => v.arn },
  )
}
