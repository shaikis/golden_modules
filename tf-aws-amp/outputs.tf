output "workspace_id" {
  description = "ID of the AMP workspace."
  value       = aws_prometheus_workspace.this.id
}

output "workspace_arn" {
  description = "ARN of the AMP workspace."
  value       = aws_prometheus_workspace.this.arn
}

output "workspace_endpoint" {
  description = "Prometheus query endpoint (use for Grafana data source)."
  value       = aws_prometheus_workspace.this.prometheus_endpoint
}

output "remote_write_url" {
  description = "Full remote_write URL for Prometheus configuration."
  value       = "${aws_prometheus_workspace.this.prometheus_endpoint}api/v1/remote_write"
}

output "query_url" {
  description = "Full query URL for Grafana or other tools."
  value       = "${aws_prometheus_workspace.this.prometheus_endpoint}api/v1/query"
}

output "irsa_role_arn" {
  description = "ARN of the IRSA IAM role for Prometheus service account. Empty when create_irsa_role = false."
  value       = var.create_irsa_role ? aws_iam_role.irsa[0].arn : ""
}

output "irsa_role_name" {
  description = "Name of the IRSA IAM role."
  value       = var.create_irsa_role ? aws_iam_role.irsa[0].name : ""
}

output "managed_scraper_id" {
  description = "ID of the AMP managed scraper. Empty when create_managed_scraper = false."
  value       = var.create_managed_scraper ? aws_prometheus_scraper.this[0].id : ""
}

output "managed_scraper_arn" {
  description = "ARN of the AMP managed scraper."
  value       = var.create_managed_scraper ? aws_prometheus_scraper.this[0].arn : ""
}

output "log_group_name" {
  description = "CloudWatch Log Group name for AMP logs."
  value       = var.enable_logging ? aws_cloudwatch_log_group.amp[0].name : ""
}

output "log_group_arn" {
  description = "CloudWatch Log Group ARN."
  value       = var.enable_logging ? aws_cloudwatch_log_group.amp[0].arn : ""
}

output "alert_manager_enabled" {
  description = "Whether the Alert Manager is enabled."
  value       = var.enable_alert_manager
}
