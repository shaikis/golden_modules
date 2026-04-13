output "file_system_id" { value = module.efs.file_system_id }
output "file_system_arn" { value = module.efs.file_system_arn }
output "dns_name" { value = module.efs.dns_name }
output "mount_target_ids" { value = module.efs.mount_target_ids }
output "access_point_ids" { value = module.efs.access_point_ids }
output "security_group_id" { value = module.efs.security_group_id }
output "replication_destination_file_system_id" {
  value = module.efs.replication_destination_file_system_id
}
output "replication_destination_file_system_ids" {
  value = module.efs.replication_destination_file_system_ids
}
output "replication_configurations" {
  value = module.efs.replication_configurations
}
