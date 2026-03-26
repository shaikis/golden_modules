# ── Serverless Collection ──────────────────────────────────────────────────────
output "collection_id" {
  description = "ID of the OpenSearch Serverless collection."
  value       = var.create_serverless ? aws_opensearchserverless_collection.this[0].id : ""
}

output "collection_arn" {
  description = "ARN of the OpenSearch Serverless collection."
  value       = var.create_serverless ? aws_opensearchserverless_collection.this[0].arn : ""
}

output "collection_endpoint" {
  description = "Data endpoint URL for the OpenSearch Serverless collection. Use this for indexing and querying."
  value       = var.create_serverless ? aws_opensearchserverless_collection.this[0].collection_endpoint : ""
}

output "dashboard_endpoint" {
  description = "OpenSearch Dashboards endpoint URL for the serverless collection."
  value       = var.create_serverless ? aws_opensearchserverless_collection.this[0].dashboard_endpoint : ""
}

output "collection_name" {
  description = "Name of the serverless collection (sanitized to meet OpenSearch naming rules)."
  value       = var.create_serverless ? local.collection_name : ""
}

output "vpc_endpoint_id" {
  description = "VPC endpoint ID for private access to the collection. Empty when network_access_type = PUBLIC."
  value       = var.create_serverless && var.network_access_type == "VPC" ? aws_opensearchserverless_vpc_endpoint.this[0].id : ""
}

output "encryption_policy_name" {
  description = "Name of the serverless encryption security policy."
  value       = var.create_serverless ? aws_opensearchserverless_security_policy.encryption[0].name : ""
}

output "network_policy_name" {
  description = "Name of the serverless network security policy."
  value       = var.create_serverless ? aws_opensearchserverless_security_policy.network[0].name : ""
}

output "data_access_policy_name" {
  description = "Name of the serverless data access policy. Empty when no principals provided."
  value       = var.create_serverless && length(var.data_access_principals) > 0 ? aws_opensearchserverless_access_policy.data[0].name : ""
}

# ── Managed Domain ─────────────────────────────────────────────────────────────
output "domain_id" {
  description = "ID of the OpenSearch managed domain."
  value       = var.create_domain ? aws_opensearch_domain.this[0].domain_id : ""
}

output "domain_arn" {
  description = "ARN of the OpenSearch managed domain."
  value       = var.create_domain ? aws_opensearch_domain.this[0].arn : ""
}

output "domain_endpoint" {
  description = "HTTPS endpoint for the OpenSearch managed domain."
  value       = var.create_domain ? "https://${aws_opensearch_domain.this[0].endpoint}" : ""
}

output "kibana_endpoint" {
  description = "OpenSearch Dashboards (Kibana) endpoint for the managed domain."
  value       = var.create_domain ? "https://${aws_opensearch_domain.this[0].dashboard_endpoint}" : ""
}

output "domain_name" {
  description = "Name of the OpenSearch managed domain."
  value       = var.create_domain ? aws_opensearch_domain.this[0].domain_name : ""
}

output "index_slow_log_group" {
  description = "CloudWatch Log Group name for index slow logs."
  value       = var.create_domain && var.enable_domain_logging ? aws_cloudwatch_log_group.index_slow[0].name : ""
}
