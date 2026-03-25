output "postgres_endpoint" { value = module.postgres_primary.db_instance_endpoint }
output "postgres_replica_endpoint" { value = module.postgres_replica.db_instance_endpoint }
output "mysql_endpoint" { value = module.mysql.db_instance_endpoint }
output "oracle_endpoint" { value = module.oracle.db_instance_endpoint }
output "sqlserver_endpoint" { value = module.sqlserver.db_instance_endpoint }
output "mariadb_endpoint" { value = module.mariadb.db_instance_endpoint }
