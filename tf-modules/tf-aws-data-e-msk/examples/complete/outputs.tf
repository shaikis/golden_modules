output "cluster_arns" {
  description = "All provisioned MSK cluster ARNs."
  value       = module.msk.cluster_arns
}

output "cluster_bootstrap_brokers_tls" {
  description = "TLS bootstrap broker strings per cluster."
  value       = module.msk.cluster_bootstrap_brokers_tls
}

output "cluster_bootstrap_brokers_sasl_iam" {
  description = "SASL/IAM bootstrap broker strings per cluster."
  value       = module.msk.cluster_bootstrap_brokers_sasl_iam
}

output "cluster_bootstrap_brokers_sasl_scram" {
  description = "SASL/SCRAM bootstrap broker strings per cluster."
  value       = module.msk.cluster_bootstrap_brokers_sasl_scram
}

output "cluster_zookeeper_connect_strings" {
  description = "ZooKeeper connection strings per cluster."
  value       = module.msk.cluster_zookeeper_connect_strings
}

output "serverless_cluster_arns" {
  description = "Serverless MSK cluster ARNs."
  value       = module.msk.serverless_cluster_arns
}

output "producer_role_arn" {
  description = "MSK producer IAM role ARN."
  value       = module.msk.producer_role_arn
}

output "consumer_role_arn" {
  description = "MSK consumer IAM role ARN."
  value       = module.msk.consumer_role_arn
}

output "configuration_arns" {
  description = "MSK configuration ARNs."
  value       = module.msk.configuration_arns
}

output "alarm_arns" {
  description = "All CloudWatch alarm ARNs."
  value       = module.msk.alarm_arns
}
