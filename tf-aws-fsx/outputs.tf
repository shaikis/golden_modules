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

# ONTAP SnapMirror
output "ontap_snapmirror_volume_relationship_ids" {
  description = "SnapMirror volume relationship identifiers (empty when enable_ontap_snapmirror = false)."
  value       = { for k, v in netapp-ontap_snapmirror_resource.volume : k => v.id }
}
output "ontap_snapmirror_svm_dr_relationship_ids" {
  description = "SnapMirror SVM DR relationship identifiers."
  value       = { for k, v in netapp-ontap_snapmirror_resource.svm_dr : k => v.id }
}
output "ontap_cluster_peer_id" {
  description = "Cluster peer relationship ID (null when SnapMirror disabled)."
  value       = try(netapp-ontap_cluster_peers_resource.this[0].id, null)
}
output "ontap_replication_summary" {
  description = "Human-readable summary of active SnapMirror replication relationships."
  value = var.enable_ontap_snapmirror && var.ontap_snapmirror != null ? {
    replication_mode        = var.ontap_snapmirror.replication_mode
    schedule                = var.ontap_snapmirror.schedule
    volume_relationships    = keys(try(var.ontap_snapmirror.volume_relationships, {}))
    svm_dr_relationships    = keys(try(var.ontap_snapmirror.svm_dr_relationships, {}))
    source_cluster          = var.ontap_snapmirror.source_management_ip
    destination_cluster     = var.ontap_snapmirror.destination_management_ip
  } : null
}
