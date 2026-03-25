# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

# ---- Catalog Databases ---------------------------------------------------

output "catalog_database_arns" {
  description = "Map of catalog database key → ARN."
  value = try({
    for k, v in aws_glue_catalog_database.this :
    k => "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${v.name}"
  }, {})
}

output "catalog_database_names" {
  description = "Map of catalog database key → name."
  value = try({
    for k, v in aws_glue_catalog_database.this :
    k => v.name
  }, {})
}

# ---- Catalog Tables ------------------------------------------------------

output "catalog_table_names" {
  description = "Map of '<database>/<table>' key → table name."
  value = {
    for k, v in aws_glue_catalog_table.this :
    k => v.name
  }
}

# ---- Crawlers ------------------------------------------------------------

output "crawler_arns" {
  description = "Map of crawler key → ARN."
  value       = try({ for k, v in aws_glue_crawler.this : k => v.arn }, {})
}

output "crawler_names" {
  description = "Map of crawler key → name."
  value       = try({ for k, v in aws_glue_crawler.this : k => v.name }, {})
}

# ---- Jobs ----------------------------------------------------------------

output "job_arns" {
  description = "Map of job key → ARN."
  value = {
    for k, v in aws_glue_job.this :
    k => v.arn
  }
}

output "job_names" {
  description = "Map of job key → name (useful for trigger references)."
  value = {
    for k, v in aws_glue_job.this :
    k => v.name
  }
}

# ---- Triggers ------------------------------------------------------------

output "trigger_arns" {
  description = "Map of trigger key → ARN."
  value       = try({ for k, v in aws_glue_trigger.this : k => v.arn }, {})
}

# ---- Workflows -----------------------------------------------------------

output "workflow_arns" {
  description = "Map of workflow key → ARN."
  value       = try({ for k, v in aws_glue_workflow.this : k => v.arn }, {})
}

# ---- Connections ---------------------------------------------------------

output "connection_arns" {
  description = "Map of connection key → ARN."
  value = try({
    for k, v in aws_glue_connection.this :
    k => "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:connection/${v.name}"
  }, {})
}

output "connection_names" {
  description = "Map of connection key → name."
  value       = try({ for k, v in aws_glue_connection.this : k => v.name }, {})
}

# ---- Schema Registry -----------------------------------------------------

output "schema_registry_arns" {
  description = "Map of registry key → ARN."
  value       = try({ for k, v in aws_glue_registry.this : k => v.arn }, {})
}

output "schema_arns" {
  description = "Map of '<registry>/<schema>' key → schema ARN."
  value       = try({ for k, v in aws_glue_schema.this : k => v.arn }, {})
}

# ---- Security Configurations ---------------------------------------------

output "security_configuration_names" {
  description = "Map of security configuration key → name."
  value = try({
    for k, v in aws_glue_security_configuration.this :
    k => v.name
  }, {})
}

# ---- IAM -----------------------------------------------------------------

output "glue_service_role_arn" {
  description = "ARN of the module-managed Glue service IAM role."
  value       = try(aws_iam_role.glue_service[0].arn, null)
}

output "glue_service_role_name" {
  description = "Name of the module-managed Glue service IAM role."
  value       = try(aws_iam_role.glue_service[0].name, null)
}
