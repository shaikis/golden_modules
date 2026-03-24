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
# NOTE: SQL Server does NOT support cross-region read replicas.
# Only automated backup replication is available.
# ---------------------------------------------------------------------------
