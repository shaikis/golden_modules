output "db_instance_id"                { value = aws_db_instance.this.id }
output "db_instance_arn"               { value = aws_db_instance.this.arn }
output "db_instance_endpoint"          { value = aws_db_instance.this.endpoint }
output "db_instance_address"           { value = aws_db_instance.this.address }
output "db_instance_port"              { value = aws_db_instance.this.port }
output "db_instance_name"              { value = aws_db_instance.this.db_name }
output "db_instance_username"          { value = aws_db_instance.this.username; sensitive = true }
output "db_instance_resource_id"       { value = aws_db_instance.this.resource_id }
output "db_master_user_secret_arn"     { value = try(aws_db_instance.this.master_user_secret[0].secret_arn, null) }
output "db_parameter_group_id"         { value = length(aws_db_parameter_group.this) > 0 ? aws_db_parameter_group.this[0].id : null }
output "enhanced_monitoring_iam_role_arn" { value = length(aws_iam_role.monitoring) > 0 ? aws_iam_role.monitoring[0].arn : null }
