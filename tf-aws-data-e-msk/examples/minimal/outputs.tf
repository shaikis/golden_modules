output "cluster_arns" {
  description = "MSK cluster ARNs."
  value       = module.msk.cluster_arns
}

output "bootstrap_brokers_sasl_iam" {
  description = "SASL/IAM bootstrap broker strings."
  value       = module.msk.cluster_bootstrap_brokers_sasl_iam
}

output "producer_role_arn" {
  description = "ARN of the MSK producer IAM role."
  value       = module.msk.producer_role_arn
}

output "consumer_role_arn" {
  description = "ARN of the MSK consumer IAM role."
  value       = module.msk.consumer_role_arn
}
