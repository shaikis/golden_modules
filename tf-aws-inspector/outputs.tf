output "enabled_resource_types" {
  description = "Resource types Inspector v2 is actively scanning."
  value       = aws_inspector2_enabler.this.resource_types
}

output "delegated_admin_account_id" {
  description = "Delegated admin account ID (null when not configured)."
  value       = try(aws_inspector2_delegated_admin_account.this[0].account_id, null)
}

output "member_account_ids" {
  description = "List of member account IDs associated with Inspector."
  value       = [for m in aws_inspector2_member_association.this : m.account_id]
}

output "suppression_rule_arns" {
  description = "ARNs of created suppression filter rules."
  value       = { for k, v in aws_inspector2_filter.suppression : k => v.arn }
}

output "findings_event_rule_arn" {
  description = "EventBridge rule ARN for findings notifications (null when disabled)."
  value       = try(aws_cloudwatch_event_rule.inspector_findings[0].arn, null)
}
