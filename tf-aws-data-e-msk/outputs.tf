# ---------------------------------------------------------------------------
# Provisioned cluster outputs
# ---------------------------------------------------------------------------

output "cluster_arns" {
  description = "Map of cluster key to ARN for all provisioned MSK clusters."
  value       = { for k, v in aws_msk_cluster.this : k => v.arn }
}

output "cluster_bootstrap_brokers_tls" {
  description = "Map of cluster key to TLS bootstrap broker connection strings."
  value       = { for k, v in aws_msk_cluster.this : k => v.bootstrap_brokers_tls }
}

output "cluster_bootstrap_brokers_sasl_iam" {
  description = "Map of cluster key to SASL/IAM bootstrap broker connection strings."
  value       = { for k, v in aws_msk_cluster.this : k => v.bootstrap_brokers_sasl_iam }
}

output "cluster_bootstrap_brokers_sasl_scram" {
  description = "Map of cluster key to SASL/SCRAM bootstrap broker connection strings."
  value       = { for k, v in aws_msk_cluster.this : k => v.bootstrap_brokers_sasl_scram }
}

output "cluster_zookeeper_connect_strings" {
  description = "Map of cluster key to ZooKeeper connection strings (Kafka < 3.x)."
  value       = { for k, v in aws_msk_cluster.this : k => v.zookeeper_connect_string }
}

output "cluster_current_version" {
  description = "Map of cluster key to the current version of the MSK cluster."
  value       = { for k, v in aws_msk_cluster.this : k => v.current_version }
}

# ---------------------------------------------------------------------------
# Serverless cluster outputs
# ---------------------------------------------------------------------------

output "serverless_cluster_arns" {
  description = "Map of serverless cluster key to ARN."
  value       = { for k, v in aws_msk_serverless_cluster.this : k => v.arn }
}

# ---------------------------------------------------------------------------
# Configuration outputs
# ---------------------------------------------------------------------------

output "configuration_arns" {
  description = "Map of configuration key to ARN."
  value       = { for k, v in aws_msk_configuration.this : k => v.arn }
}

output "configuration_latest_revisions" {
  description = "Map of configuration key to latest revision number."
  value       = { for k, v in aws_msk_configuration.this : k => v.latest_revision }
}

# ---------------------------------------------------------------------------
# IAM outputs
# ---------------------------------------------------------------------------

output "producer_role_arn" {
  description = "ARN of the IAM role for MSK producers. Empty string when create_iam_role = false."
  value       = var.create_iam_role ? aws_iam_role.producer[0].arn : ""
}

output "producer_role_name" {
  description = "Name of the IAM role for MSK producers. Empty string when create_iam_role = false."
  value       = var.create_iam_role ? aws_iam_role.producer[0].name : ""
}

output "consumer_role_arn" {
  description = "ARN of the IAM role for MSK consumers. Empty string when create_iam_role = false."
  value       = var.create_iam_role ? aws_iam_role.consumer[0].arn : ""
}

output "consumer_role_name" {
  description = "Name of the IAM role for MSK consumers. Empty string when create_iam_role = false."
  value       = var.create_iam_role ? aws_iam_role.consumer[0].name : ""
}

# ---------------------------------------------------------------------------
# VPC connection outputs
# ---------------------------------------------------------------------------

output "vpc_connection_arns" {
  description = "Map of VPC connection key to ARN."
  value       = { for k, v in aws_msk_vpc_connection.this : k => v.arn }
}

# ---------------------------------------------------------------------------
# Alarm outputs
# ---------------------------------------------------------------------------

output "alarm_arns" {
  description = "Map of alarm names to ARNs for all CloudWatch alarms created."
  value = var.create_alarms ? merge(
    { for k, v in aws_cloudwatch_metric_alarm.kafka_disk_used : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.memory_used : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.cpu_user : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.network_rx_dropped : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.network_tx_dropped : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.under_replicated_partitions : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.active_controller_count : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.offline_partitions_count : k => v.arn },
  ) : {}
}

# ---------------------------------------------------------------------------
# Convenience: region and account
# ---------------------------------------------------------------------------

output "aws_region" {
  description = "AWS region where resources are deployed."
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID where resources are deployed."
  value       = data.aws_caller_identity.current.account_id
}
