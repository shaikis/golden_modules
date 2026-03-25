output "db_instance_endpoint" {
  description = "RDS instance connection endpoint."
  value       = module.rds.db_instance_endpoint
}

output "db_instance_arn" {
  description = "ARN of the RDS instance."
  value       = module.rds.db_instance_arn
}
