# ---------------------------------------------------------------------------
# Primary instance outputs
# ---------------------------------------------------------------------------
output "primary_db_instance_id" { value = module.rds_primary.db_instance_id }
output "primary_db_instance_arn" { value = module.rds_primary.db_instance_arn }
output "primary_db_instance_endpoint" { value = module.rds_primary.db_instance_endpoint }
output "primary_db_instance_port" { value = module.rds_primary.db_instance_port }
output "primary_master_user_secret_arn" {
  value     = module.rds_primary.db_master_user_secret_arn
  sensitive = true
}

# ---------------------------------------------------------------------------
# DR replica outputs (only populated when create_cross_region_replica = true)
# ---------------------------------------------------------------------------
output "dr_replica_endpoint" {
  description = "Endpoint of the cross-region read replica (null when disabled)"
  value       = var.create_cross_region_replica ? module.rds_replica[0].db_instance_endpoint : null
}

output "dr_replica_arn" {
  description = "ARN of the cross-region read replica (null when disabled)"
  value       = var.create_cross_region_replica ? module.rds_replica[0].db_instance_arn : null
}
