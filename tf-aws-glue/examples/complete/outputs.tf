# ---------------------------------------------------------------------------
# Example outputs — surface key values from the module
# ---------------------------------------------------------------------------

output "glue_service_role_arn" {
  description = "ARN of the Glue service IAM role."
  value       = module.glue.glue_service_role_arn
}

output "glue_service_role_name" {
  description = "Name of the Glue service IAM role."
  value       = module.glue.glue_service_role_name
}

output "catalog_database_names" {
  description = "Names of the three catalog databases created."
  value       = module.glue.catalog_database_names
}

output "crawler_arns" {
  description = "ARNs of all crawlers."
  value       = module.glue.crawler_arns
}

output "job_names" {
  description = "Names of all Glue ETL jobs."
  value       = module.glue.job_names
}

output "job_arns" {
  description = "ARNs of all Glue ETL jobs."
  value       = module.glue.job_arns
}

output "workflow_arns" {
  description = "ARNs of all Glue workflows."
  value       = module.glue.workflow_arns
}

output "trigger_arns" {
  description = "ARNs of all Glue triggers."
  value       = module.glue.trigger_arns
}

output "connection_arns" {
  description = "ARNs of all Glue connections."
  value       = module.glue.connection_arns
}

output "schema_registry_arns" {
  description = "ARNs of all schema registries."
  value       = module.glue.schema_registry_arns
}

output "schema_arns" {
  description = "ARNs of all schemas."
  value       = module.glue.schema_arns
}

output "security_configuration_names" {
  description = "Names of all security configurations."
  value       = module.glue.security_configuration_names
}
