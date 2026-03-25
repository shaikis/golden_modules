# Windows
output "windows_fs_id" { value = try(aws_fsx_windows_file_system.this[0].id, null) }
output "windows_fs_dns_name" { value = try(aws_fsx_windows_file_system.this[0].dns_name, null) }
output "windows_fs_remote_admin_endpoint" { value = try(aws_fsx_windows_file_system.this[0].remote_administration_endpoint, null) }

# Lustre
output "lustre_fs_id" { value = try(aws_fsx_lustre_file_system.this[0].id, null) }
output "lustre_fs_dns_name" { value = try(aws_fsx_lustre_file_system.this[0].dns_name, null) }
output "lustre_mount_name" { value = try(aws_fsx_lustre_file_system.this[0].mount_name, null) }

# ONTAP
output "ontap_fs_id" { value = try(aws_fsx_ontap_file_system.this[0].id, null) }
output "ontap_fs_endpoints" { value = try(aws_fsx_ontap_file_system.this[0].endpoints, null) }
output "ontap_svm_ids" { value = { for k, v in aws_fsx_ontap_storage_virtual_machine.this : k => v.id } }
output "ontap_volume_ids" { value = { for k, v in aws_fsx_ontap_volume.this : k => v.id } }
output "ontap_volume_junction_paths" { value = { for k, v in aws_fsx_ontap_volume.this : k => v.junction_path } }

# OpenZFS
output "openzfs_fs_id" { value = try(aws_fsx_openzfs_file_system.this[0].id, null) }
output "openzfs_root_volume_id" { value = try(aws_fsx_openzfs_file_system.this[0].root_volume_id, null) }
output "openzfs_fs_dns_name" { value = try(aws_fsx_openzfs_file_system.this[0].dns_name, null) }
output "openzfs_volume_ids" { value = { for k, v in aws_fsx_openzfs_volume.this : k => v.id } }

# ONTAP AWS Backup
output "ontap_backup_vault_arn" { value = try(aws_backup_vault.ontap[0].arn, null) }
output "ontap_backup_plan_id" { value = try(aws_backup_plan.ontap[0].id, null) }
output "ontap_backup_plan_arn" { value = try(aws_backup_plan.ontap[0].arn, null) }
