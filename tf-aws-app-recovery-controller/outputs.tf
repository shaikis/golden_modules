output "cluster_arn" {
  description = "ARC cluster ARN."
  value       = local.cluster_arn
}

output "cluster_endpoints" {
  description = "ARC cluster endpoints (5 global endpoints for routing control operations)."
  value       = var.create_cluster ? aws_route53recoverycontrolconfig_cluster.this[0].cluster_endpoints : []
}

output "control_panel_arns" {
  description = "Map of control panel key to ARN."
  value       = { for k, v in aws_route53recoverycontrolconfig_control_panel.this : k => v.arn }
}

output "routing_control_arns" {
  description = "Map of routing control key to ARN."
  value       = { for k, v in aws_route53recoverycontrolconfig_routing_control.this : k => v.arn }
}

output "routing_control_states" {
  description = <<-EOT
    Map of routing control key to its default state.
    IMPORTANT: Terraform manages the resource, not the state value.
    Use the ARC console, AWS CLI, or SDK to toggle routing controls during failover:
      aws route53-recovery-cluster update-routing-control-state \
        --routing-control-arn <arn> \
        --routing-control-state ON|OFF
  EOT
  value = { for k, v in aws_route53recoverycontrolconfig_routing_control.this : k => "TOGGLE_VIA_ARC_API" }
}

output "safety_rule_arns" {
  description = "Map of safety rule key to ARN."
  value = merge(
    { for k, v in aws_route53recoverycontrolconfig_safety_rule.assertion : k => v.arn },
    { for k, v in aws_route53recoverycontrolconfig_safety_rule.gating : k => v.arn }
  )
}

output "health_check_ids" {
  description = "Map of health check key to Route 53 health check ID (use in DNS failover records)."
  value       = { for k, v in aws_route53_health_check.routing_control : k => v.id }
}

output "health_check_arns" {
  description = "Map of health check key to Route 53 health check ARN."
  value       = { for k, v in aws_route53_health_check.routing_control : k => v.arn }
}

output "recovery_group_arn" {
  description = "Recovery group ARN (null when not configured)."
  value       = try(aws_route53recoveryreadiness_recovery_group.this[0].arn, null)
}

output "cell_arns" {
  description = "Map of cell name to ARN."
  value       = { for k, v in aws_route53recoveryreadiness_cell.this : k => v.arn }
}

output "readiness_check_arns" {
  description = "Map of readiness check key to ARN."
  value       = { for k, v in aws_route53recoveryreadiness_readiness_check.this : k => v.arn }
}

output "resource_set_arns" {
  description = "Map of resource set key to ARN."
  value       = { for k, v in aws_route53recoveryreadiness_resource_set.this : k => v.arn }
}
