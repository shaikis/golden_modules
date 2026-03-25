output "environment_arns" {
  description = "Map of environment name => ARN."
  value       = module.mwaa.environment_arns
}

output "environment_names" {
  description = "Map of environment name => resource name."
  value       = module.mwaa.environment_names
}

output "webserver_urls" {
  description = "Map of environment name => Airflow webserver URL."
  value       = module.mwaa.webserver_urls
}

output "mwaa_role_arn" {
  description = "MWAA execution IAM role ARN."
  value       = module.mwaa.mwaa_role_arn
}

output "alarm_arns" {
  description = "Map of alarm name => ARN."
  value       = module.mwaa.alarm_arns
}
