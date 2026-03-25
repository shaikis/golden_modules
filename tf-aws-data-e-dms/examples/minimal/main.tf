# Minimal example: one DMS replication instance with a MySQL source
# and a PostgreSQL target. Replication task uses default table mappings.

module "dms" {
  source = "../../"

  subnet_groups = {
    main = {
      description = "DMS replication subnet group"
      subnet_ids  = ["subnet-aaa", "subnet-bbb"]
    }
  }

  replication_instances = {
    main = {
      replication_instance_class  = "dms.t3.medium"
      replication_subnet_group_id = "main"
    }
  }

  endpoints = {
    mysql-source = {
      endpoint_type = "source"
      engine_name   = "mysql"
      server_name   = "mysql.example.com"
      port          = 3306
      database_name = "appdb"
      username      = "dms_user"
      password      = "changeme"
      ssl_mode      = "none"
    }

    postgres-target = {
      endpoint_type = "target"
      engine_name   = "postgres"
      server_name   = "postgres.example.com"
      port          = 5432
      database_name = "appdb"
      username      = "dms_user"
      password      = "changeme"
      ssl_mode      = "none"
    }
  }

  replication_tasks = {
    mysql-to-postgres = {
      replication_instance_key = "main"
      source_endpoint_key      = "mysql-source"
      target_endpoint_key      = "postgres-target"
      migration_type           = "full-load-and-cdc"
    }
  }
}
