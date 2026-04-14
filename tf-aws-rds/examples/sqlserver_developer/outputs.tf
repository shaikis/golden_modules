output "db_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "db_engine_version" {
  value = module.rds.db_instance_engine_version
}

output "custom_engine_version_name" {
  value = module.rds.sqlserver_developer_custom_engine_version_name
}
