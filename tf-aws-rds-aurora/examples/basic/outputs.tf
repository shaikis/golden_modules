output "cluster_endpoint" {
  description = "Aurora cluster writer endpoint."
  value       = module.aurora.cluster_endpoint
}

output "cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint."
  value       = module.aurora.cluster_reader_endpoint
}

output "cluster_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master password."
  value       = module.aurora.cluster_master_user_secret_arn
}
