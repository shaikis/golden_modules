output "environment_arns" {
  description = "MWAA environment ARNs."
  value       = module.mwaa.environment_arns
}

output "webserver_urls" {
  description = "Airflow webserver URLs."
  value       = module.mwaa.webserver_urls
}

output "mwaa_role_arn" {
  description = "MWAA execution role ARN."
  value       = module.mwaa.mwaa_role_arn
}
