output "cluster_id" {
  description = "Identifier of the DocumentDB cluster."
  value       = aws_docdb_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the DocumentDB cluster."
  value       = aws_docdb_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Writer endpoint of the DocumentDB cluster. Use for all write operations."
  value       = aws_docdb_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint for read-only connections. Load-balances across all reader instances."
  value       = aws_docdb_cluster.this.reader_endpoint
}

output "port" {
  description = "DocumentDB port (default 27017)."
  value       = aws_docdb_cluster.this.port
}

output "master_username" {
  description = "Master username for the DocumentDB cluster."
  value       = aws_docdb_cluster.this.master_username
}

output "credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DocumentDB credentials and connection URI."
  value       = aws_secretsmanager_secret.docdb_credentials.arn
}

output "credentials_secret_name" {
  description = "Name of the Secrets Manager secret."
  value       = aws_secretsmanager_secret.docdb_credentials.name
}

output "security_group_id" {
  description = "ID of the DocumentDB security group. Add this to the allowed_security_group_ids of application modules."
  value       = aws_security_group.docdb.id
}

output "subnet_group_name" {
  description = "Name of the DocumentDB subnet group."
  value       = aws_docdb_subnet_group.this.name
}

output "instance_ids" {
  description = "List of DocumentDB instance identifiers."
  value       = [for i in aws_docdb_cluster_instance.this : i.id]
}

output "cluster_resource_id" {
  description = "Resource ID of the DocumentDB cluster."
  value       = aws_docdb_cluster.this.cluster_resource_id
}

output "connection_string" {
  description = "MongoDB-compatible connection string for DocumentDB."
  value       = "mongodb://${var.master_username}:***@${aws_docdb_cluster.this.endpoint}:${var.port}/?tls=true&tlsCAFile=/etc/ssl/certs/rds-combined-ca-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
  sensitive   = false
}
