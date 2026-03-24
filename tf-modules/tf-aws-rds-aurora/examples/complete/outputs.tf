output "primary_cluster_endpoint" {
  description = "Primary Aurora cluster writer endpoint."
  value       = module.aurora_primary.cluster_endpoint
}

output "primary_cluster_reader_endpoint" {
  description = "Primary Aurora cluster reader endpoint."
  value       = module.aurora_primary.cluster_reader_endpoint
}

output "dr_cluster_endpoint" {
  description = "DR Aurora cluster endpoint."
  value       = module.aurora_dr.cluster_endpoint
}

output "serverless_cluster_endpoint" {
  description = "Serverless v2 Aurora cluster endpoint."
  value       = module.aurora_serverless.cluster_endpoint
}

output "cluster_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master password."
  value       = module.aurora_primary.cluster_master_user_secret_arn
}

output "global_cluster_id" {
  description = "Global cluster identifier."
  value       = module.aurora_primary.global_cluster_id
}
