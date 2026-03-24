# ── Provisioned Clusters ──────────────────────────────────────────────────────

output "cluster_ids" {
  description = "Map of cluster key to cluster identifier."
  value       = { for k, v in aws_redshift_cluster.this : k => v.cluster_identifier }
}

output "cluster_arns" {
  description = "Map of cluster key to cluster ARN."
  value       = { for k, v in aws_redshift_cluster.this : k => v.arn }
}

output "cluster_endpoints" {
  description = "Map of cluster key to cluster endpoint address."
  value       = { for k, v in aws_redshift_cluster.this : k => v.endpoint }
}

output "cluster_port" {
  description = "Map of cluster key to cluster port."
  value       = { for k, v in aws_redshift_cluster.this : k => v.port }
}

output "cluster_dns_names" {
  description = "Map of cluster key to cluster DNS name."
  value       = { for k, v in aws_redshift_cluster.this : k => v.dns_name }
}

output "cluster_database_names" {
  description = "Map of cluster key to database name."
  value       = { for k, v in aws_redshift_cluster.this : k => v.database_name }
}

output "cluster_master_usernames" {
  description = "Map of cluster key to master username."
  value       = { for k, v in aws_redshift_cluster.this : k => v.master_username }
}

# ── Serverless ────────────────────────────────────────────────────────────────

output "serverless_namespace_arns" {
  description = "Map of namespace key to serverless namespace ARN."
  value       = { for k, v in aws_redshiftserverless_namespace.this : k => v.arn }
}

output "serverless_namespace_ids" {
  description = "Map of namespace key to serverless namespace ID."
  value       = { for k, v in aws_redshiftserverless_namespace.this : k => v.id }
}

output "serverless_workgroup_arns" {
  description = "Map of workgroup key to serverless workgroup ARN."
  value       = { for k, v in aws_redshiftserverless_workgroup.this : k => v.arn }
}

output "serverless_workgroup_endpoints" {
  description = "Map of workgroup key to serverless workgroup endpoint."
  value       = { for k, v in aws_redshiftserverless_workgroup.this : k => v.endpoint }
}

output "serverless_workgroup_ids" {
  description = "Map of workgroup key to serverless workgroup ID."
  value       = { for k, v in aws_redshiftserverless_workgroup.this : k => v.id }
}

# ── Subnet Groups ─────────────────────────────────────────────────────────────

output "subnet_group_names" {
  description = "Map of subnet group key to subnet group name."
  value       = { for k, v in aws_redshift_subnet_group.this : k => v.name }
}

output "subnet_group_arns" {
  description = "Map of subnet group key to subnet group ARN."
  value       = { for k, v in aws_redshift_subnet_group.this : k => v.arn }
}

# ── Parameter Groups ──────────────────────────────────────────────────────────

output "parameter_group_names" {
  description = "Map of parameter group key to parameter group name."
  value       = { for k, v in aws_redshift_parameter_group.this : k => v.name }
}

# ── IAM Roles ─────────────────────────────────────────────────────────────────

output "redshift_role_arn" {
  description = "ARN of the Redshift service IAM role."
  value       = var.create_iam_role ? aws_iam_role.redshift[0].arn : var.role_arn
}

output "scheduled_action_role_arn" {
  description = "ARN of the Redshift scheduled actions IAM role."
  value       = var.create_iam_role ? aws_iam_role.redshift_scheduler[0].arn : null
}

output "redshift_role_name" {
  description = "Name of the Redshift service IAM role."
  value       = var.create_iam_role ? aws_iam_role.redshift[0].name : null
}

# ── Snapshot Schedules ────────────────────────────────────────────────────────

output "snapshot_schedule_arns" {
  description = "Map of snapshot schedule key to schedule ARN."
  value       = { for k, v in aws_redshift_snapshot_schedule.this : k => v.arn }
}

output "snapshot_copy_grant_arns" {
  description = "Map of snapshot copy grant key to grant ARN."
  value       = { for k, v in aws_redshift_snapshot_copy_grant.this : k => v.arn }
}

# ── Alarms ────────────────────────────────────────────────────────────────────

output "alarm_arns" {
  description = "Map of alarm key to CloudWatch alarm ARN."
  value = merge(
    { for k, v in aws_cloudwatch_metric_alarm.cluster : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.serverless : k => v.arn }
  )
}

# ── Endpoint Accesses ─────────────────────────────────────────────────────────

output "endpoint_access_addresses" {
  description = "Map of endpoint key to VPC endpoint address."
  value       = { for k, v in aws_redshift_endpoint_access.this : k => v.address }
}

# ── Metadata ──────────────────────────────────────────────────────────────────

output "aws_region" {
  description = "AWS region where resources are deployed."
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID where resources are deployed."
  value       = data.aws_caller_identity.current.account_id
}
