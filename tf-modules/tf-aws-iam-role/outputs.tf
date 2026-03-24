output "role_name" { value = aws_iam_role.this.name }
output "role_arn" { value = aws_iam_role.this.arn }
output "role_id" { value = aws_iam_role.this.id }
output "role_unique_id" { value = aws_iam_role.this.unique_id }
output "instance_profile_id" { value = length(aws_iam_instance_profile.this) > 0 ? aws_iam_instance_profile.this[0].id : null }
output "instance_profile_arn" { value = length(aws_iam_instance_profile.this) > 0 ? aws_iam_instance_profile.this[0].arn : null }
output "instance_profile_name" { value = length(aws_iam_instance_profile.this) > 0 ? aws_iam_instance_profile.this[0].name : null }
