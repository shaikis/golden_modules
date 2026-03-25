output "secret_id" { value = aws_secretsmanager_secret.this.id }
output "secret_arn" { value = aws_secretsmanager_secret.this.arn }
output "secret_name" { value = aws_secretsmanager_secret.this.name }
output "secret_version_id" { value = length(aws_secretsmanager_secret_version.this) > 0 ? aws_secretsmanager_secret_version.this[0].version_id : null }
