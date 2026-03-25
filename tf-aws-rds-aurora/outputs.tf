output "cluster_id" { value = aws_rds_cluster.this.id }
output "cluster_arn" { value = aws_rds_cluster.this.arn }
output "cluster_endpoint" { value = aws_rds_cluster.this.endpoint }
output "cluster_reader_endpoint" { value = aws_rds_cluster.this.reader_endpoint }
output "cluster_port" { value = aws_rds_cluster.this.port }
output "cluster_database_name" { value = aws_rds_cluster.this.database_name }
output "cluster_master_username" {
  value     = aws_rds_cluster.this.master_username
  sensitive = true
}
output "cluster_master_user_secret_arn" { value = try(aws_rds_cluster.this.master_user_secret[0].secret_arn, null) }
output "cluster_resource_id" { value = aws_rds_cluster.this.cluster_resource_id }
output "cluster_members" { value = { for k, v in aws_rds_cluster_instance.this : k => v.id } }
output "global_cluster_id" { value = length(aws_rds_global_cluster.this) > 0 ? aws_rds_global_cluster.this[0].id : null }
