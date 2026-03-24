output "volume_ids" { value = { for k, v in aws_ebs_volume.this : k => v.id } }
output "volume_arns" { value = { for k, v in aws_ebs_volume.this : k => v.arn } }
output "attachment_device_names" { value = { for k, v in aws_volume_attachment.this : k => v.device_name } }
output "dlm_policy_id" { value = try(aws_dlm_lifecycle_policy.this[0].id, null) }
