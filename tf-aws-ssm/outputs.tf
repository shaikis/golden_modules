# ── Parameter Store ─────────────────────────────────────────────────────────────
output "parameter_arns" {
  description = "Map of parameter path => ARN."
  value       = { for k, v in aws_ssm_parameter.this : k => v.arn }
}

output "parameter_names" {
  description = "Map of parameter key => full SSM path."
  value       = { for k, v in aws_ssm_parameter.this : k => v.name }
}

output "parameter_versions" {
  description = "Map of parameter path => current version number."
  value       = { for k, v in aws_ssm_parameter.this : k => v.version }
}

# ── Patch Baselines ──────────────────────────────────────────────────────────────
output "patch_baseline_ids" {
  description = "Map of baseline key => baseline ID."
  value       = { for k, v in aws_ssm_patch_baseline.this : k => v.id }
}

output "patch_baseline_arns" {
  description = "Map of baseline key => baseline ARN."
  value       = { for k, v in aws_ssm_patch_baseline.this : k => v.arn }
}

# ── Maintenance Windows ──────────────────────────────────────────────────────────
output "maintenance_window_ids" {
  description = "Map of window key => maintenance window ID."
  value       = { for k, v in aws_ssm_maintenance_window.this : k => v.id }
}

output "maintenance_window_role_arn" {
  description = "ARN of the IAM role for maintenance window tasks."
  value       = length(aws_iam_role.maintenance_window) > 0 ? aws_iam_role.maintenance_window[0].arn : null
}

# ── Session Manager ──────────────────────────────────────────────────────────────
output "session_manager_policy_arn" {
  description = "ARN of the IAM policy to attach to EC2 instance roles for Session Manager. Replaces SSH bastion hosts."
  value       = var.enable_session_manager ? aws_iam_policy.session_manager[0].arn : null
}

output "session_manager_log_group_name" {
  description = "CloudWatch Log Group name for Session Manager session logs."
  value       = var.enable_session_manager && var.session_manager_cloudwatch_log_group != null ? aws_cloudwatch_log_group.session_manager[0].name : null
}

# ── SSM Documents ────────────────────────────────────────────────────────────────
output "document_arns" {
  description = "Map of document key => ARN."
  value       = { for k, v in aws_ssm_document.custom : k => v.arn }
}

output "document_names" {
  description = "Map of document key => SSM document name."
  value       = { for k, v in aws_ssm_document.custom : k => v.name }
}

# ── AppConfig ────────────────────────────────────────────────────────────────────
output "appconfig_application_id" {
  description = "AppConfig application ID."
  value       = var.enable_appconfig ? aws_appconfig_application.this[0].id : null
}

output "appconfig_application_arn" {
  description = "AppConfig application ARN."
  value       = var.enable_appconfig ? aws_appconfig_application.this[0].arn : null
}

output "appconfig_environment_ids" {
  description = "Map of environment name => AppConfig environment ID."
  value       = { for k, v in aws_appconfig_environment.this : k => v.environment_id }
}

output "appconfig_configuration_profile_ids" {
  description = "Map of profile name => configuration profile ID."
  value       = { for k, v in aws_appconfig_configuration_profile.this : k => v.configuration_profile_id }
}

output "appconfig_deployment_strategy_id" {
  description = "AppConfig deployment strategy ID."
  value       = var.enable_appconfig ? aws_appconfig_deployment_strategy.this[0].id : null
}

# ── Associations ─────────────────────────────────────────────────────────────────
output "association_ids" {
  description = "Map of association key => association ID."
  value       = { for k, v in aws_ssm_association.this : k => v.association_id }
}

# ── Resource Data Sync ───────────────────────────────────────────────────────────
output "resource_data_sync_names" {
  description = "Map of sync key => resource data sync name."
  value       = { for k, v in aws_ssm_resource_data_sync.this : k => v.name }
}

# ── Hybrid Activation ────────────────────────────────────────────────────────────
output "activation_id" {
  description = "SSM Activation ID. Use with activation_code to register on-premises servers."
  value       = var.create_activation ? aws_ssm_activation.this[0].id : null
}

output "activation_code" {
  description = "Activation code for registering on-premises servers. Treat as sensitive."
  value       = var.create_activation ? aws_ssm_activation.this[0].activation_code : null
  sensitive   = true
}

output "activation_role_arn" {
  description = "IAM role ARN for hybrid activation."
  value       = var.create_activation ? aws_iam_role.activation[0].arn : null
}
