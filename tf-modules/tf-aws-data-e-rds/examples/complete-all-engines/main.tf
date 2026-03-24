# Demonstrates all engine types, read replica, Multi-AZ, option groups
provider "aws" { region = var.aws_region }

module "kms" { source = "../../../tf-aws-kms"; name = "rds-prod"; environment = "prod" }

# ──────────────────────────────────────────────────────────────
# 1. PostgreSQL – Primary + Read Replica
# ──────────────────────────────────────────────────────────────
module "postgres_primary" {
  source      = "../../"
  name        = "pg-primary"
  environment = "prod"
  engine         = "postgres"
  engine_version = "15.5"
  instance_class = "db.r6g.large"
  db_name        = "appdb"
  manage_master_user_password   = true
  master_user_secret_kms_key_id = module.kms.key_arn
  multi_az               = true
  db_subnet_group_name   = "prod-db-subnet-group"
  vpc_security_group_ids = ["sg-0aa"]
  kms_key_id             = module.kms.key_arn
  backup_retention_period = 30
  deletion_protection    = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled = true
  performance_insights_kms_key_id = module.kms.key_arn
}

module "postgres_replica" {
  source                = "../../"
  name                  = "pg-replica"
  environment           = "prod"
  engine                = "postgres"
  engine_version        = "15.5"
  instance_class        = "db.r6g.large"
  replicate_source_db   = module.postgres_primary.db_instance_arn   # ← Read Replica
  db_subnet_group_name  = "prod-db-subnet-group"
  vpc_security_group_ids = ["sg-0aa"]
  kms_key_id            = module.kms.key_arn
  backup_retention_period = 0  # read replicas cannot have automated backup
  skip_final_snapshot   = true
  deletion_protection   = false
  multi_az              = false
  manage_master_user_password = false
  performance_insights_enabled = true
}

# ──────────────────────────────────────────────────────────────
# 2. MySQL with Option Group
# ──────────────────────────────────────────────────────────────
resource "aws_db_option_group" "mysql" {
  name                     = "prod-mysql-options"
  option_group_description = "MySQL options for prod"
  engine_name              = "mysql"
  major_engine_version     = "8.0"

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
    option_settings {
      name  = "SERVER_AUDIT_EVENTS"
      value = "CONNECT,QUERY"
    }
  }
}

module "mysql" {
  source         = "../../"
  name           = "mysql-prod"
  environment    = "prod"
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.r6g.large"
  db_name        = "myapp"
  manage_master_user_password = true
  multi_az               = true
  db_subnet_group_name   = "prod-db-subnet-group"
  vpc_security_group_ids = ["sg-0bb"]
  kms_key_id             = module.kms.key_arn
  option_group_name      = aws_db_option_group.mysql.name
  backup_retention_period = 14
  deletion_protection    = true
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery", "audit"]
}

# ──────────────────────────────────────────────────────────────
# 3. Oracle Enterprise Edition
# ──────────────────────────────────────────────────────────────
module "oracle" {
  source         = "../../"
  name           = "oracle-prod"
  environment    = "prod"
  engine         = "oracle-ee"
  engine_version = "19.0.0.0.ru-2023-10.rur-2023-10.r1"
  instance_class = "db.m5.large"
  license_model  = "bring-your-own-license"
  db_name        = "ORCL"
  character_set_name = "AL32UTF8"
  manage_master_user_password = true
  multi_az               = true
  db_subnet_group_name   = "prod-db-subnet-group"
  vpc_security_group_ids = ["sg-0cc"]
  kms_key_id             = module.kms.key_arn
  allocated_storage      = 200
  max_allocated_storage  = 1000
  storage_type           = "io1"
  iops                   = 3000
  backup_retention_period = 14
  deletion_protection    = true
  enabled_cloudwatch_logs_exports = ["alert", "audit", "listener", "trace"]
}

# ──────────────────────────────────────────────────────────────
# 4. SQL Server Enterprise Edition
# ──────────────────────────────────────────────────────────────
module "sqlserver" {
  source         = "../../"
  name           = "sqlserver-prod"
  environment    = "prod"
  engine         = "sqlserver-ee"
  engine_version = "15.00.4345.5.v1"
  instance_class = "db.m5.large"
  license_model  = "license-included"
  timezone       = "Eastern Standard Time"
  manage_master_user_password = true
  multi_az               = false  # Multi-AZ for sqlserver uses different API
  db_subnet_group_name   = "prod-db-subnet-group"
  vpc_security_group_ids = ["sg-0dd"]
  kms_key_id             = module.kms.key_arn
  allocated_storage      = 200
  storage_type           = "gp3"
  backup_retention_period = 14
  deletion_protection    = true
  enabled_cloudwatch_logs_exports = ["error", "agent"]
}

# ──────────────────────────────────────────────────────────────
# 5. MariaDB
# ──────────────────────────────────────────────────────────────
module "mariadb" {
  source         = "../../"
  name           = "mariadb-prod"
  environment    = "prod"
  engine         = "mariadb"
  engine_version = "10.11.5"
  instance_class = "db.t3.large"
  db_name        = "webapp"
  manage_master_user_password = true
  multi_az               = true
  db_subnet_group_name   = "prod-db-subnet-group"
  vpc_security_group_ids = ["sg-0ee"]
  kms_key_id             = module.kms.key_arn
  backup_retention_period = 7
  deletion_protection    = true
}

