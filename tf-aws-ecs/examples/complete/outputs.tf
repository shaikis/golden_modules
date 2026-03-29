output "cluster_name" {
  value = module.ecs.cluster_name
}

output "service_ids" {
  value = module.ecs.service_ids
}

output "efs_file_system_id" {
  value = module.efs.file_system_id
}

output "efs_access_point_ids" {
  value = module.efs.access_point_ids
}
