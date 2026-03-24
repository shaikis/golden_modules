# ---------------------------------------------------------------------------
# Global cluster outputs
# ---------------------------------------------------------------------------
output "global_cluster_id" { value = aws_rds_global_cluster.this.id }

# ---------------------------------------------------------------------------
# Primary cluster outputs
# ---------------------------------------------------------------------------
output "primary_cluster_id" { value = aws_rds_cluster.primary.id }
output "primary_cluster_arn" { value = aws_rds_cluster.primary.arn }
output "primary_cluster_endpoint" { value = aws_rds_cluster.primary.endpoint }
output "primary_reader_endpoint" { value = aws_rds_cluster.primary.reader_endpoint }
output "primary_master_user_secret_arn" {
  value     = try(aws_rds_cluster.primary.master_user_secret[0].secret_arn, null)
  sensitive = true
}

# ---------------------------------------------------------------------------
# Secondary (DR) cluster outputs (only when create_secondary_region = true)
# ---------------------------------------------------------------------------
output "dr_cluster_endpoint" {
  description = "Writer endpoint of the DR Aurora cluster (null when disabled)"
  value       = var.create_secondary_region ? aws_rds_cluster.secondary[0].endpoint : null
}

output "dr_reader_endpoint" {
  description = "Reader endpoint of the DR Aurora cluster (null when disabled)"
  value       = var.create_secondary_region ? aws_rds_cluster.secondary[0].reader_endpoint : null
}
