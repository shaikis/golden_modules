output "source_bucket_id" { value = aws_s3_bucket.source.id }
output "source_bucket_arn" { value = aws_s3_bucket.source.arn }
output "srr_bucket_id" { value = length(aws_s3_bucket.srr) > 0 ? aws_s3_bucket.srr[0].id : null }
output "srr_bucket_arn" { value = length(aws_s3_bucket.srr) > 0 ? aws_s3_bucket.srr[0].arn : null }
output "replication_role_arn" { value = length(aws_iam_role.replication) > 0 ? aws_iam_role.replication[0].arn : var.replication_role_arn }
output "backup_vault_arn" { value = length(aws_backup_vault.this) > 0 ? aws_backup_vault.this[0].arn : null }
output "backup_plan_id" { value = length(aws_backup_plan.this) > 0 ? aws_backup_plan.this[0].id : null }
