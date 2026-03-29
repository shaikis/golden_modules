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
  storage_type           = "gp3"
  storage_throughput     = 500       # MB/s; gp3 default is 125
  backup_retention_period = 30
  deletion_protection    = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = true
  performance_insights_kms_key_id = module.kms.key_arn
  # IAM auth — lets IAM roles authenticate without a password (pg 9.5+)
  iam_database_authentication_enabled = true
  # Blue/Green — enables zero-downtime major version upgrades
  blue_green_update = { enabled = true }
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
# 2. MySQL with Option Group (created inside the module)
# ──────────────────────────────────────────────────────────────
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
  backup_retention_period = 14
  deletion_protection    = true
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery", "audit"]
  # IAM auth for MySQL (application connects using aws_db_auth_token)
  iam_database_authentication_enabled = true
  # Blue/Green — zero-downtime schema changes and minor version upgrades
  blue_green_update = { enabled = true }
  # Option group created inline by the module
  create_option_group               = true
  option_group_engine_name          = "mysql"
  option_group_major_engine_version = "8.0"
  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"
      option_settings = [
        { name = "SERVER_AUDIT_EVENTS", value = "CONNECT,QUERY_DDL,QUERY_DML" },
        { name = "SERVER_AUDIT_EXCL_USERS", value = "rdsadmin" },
      ]
    },
  ]
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
  character_set_name       = "AL32UTF8"
  nchar_character_set_name = "AL16UTF16"   # national charset for NCHAR/NVARCHAR2
  manage_master_user_password = true
  multi_az               = true
  db_subnet_group_name   = "prod-db-subnet-group"
  vpc_security_group_ids = ["sg-0cc"]
  kms_key_id             = module.kms.key_arn
  allocated_storage      = 200
  max_allocated_storage  = 1000
  storage_type           = "io1"
  iops                   = 3000
  dedicated_log_volume   = true   # separate EBS volume for Oracle redo log
  backup_retention_period = 14
  deletion_protection    = true
  enabled_cloudwatch_logs_exports = ["alert", "audit", "listener", "trace"]
  # Oracle option group: Native Network Encryption + Timezone auto-upgrade
  create_option_group               = true
  option_group_engine_name          = "oracle-ee"
  option_group_major_engine_version = "19"
  options = [
    {
      option_name = "NATIVE_NETWORK_ENCRYPTION"
      option_settings = [
        { name = "SQLNET.ENCRYPTION_SERVER",        value = "REQUIRED" },
        { name = "SQLNET.ENCRYPTION_TYPES_SERVER",  value = "AES256" },
        { name = "SQLNET.CRYPTO_CHECKSUM_SERVER",   value = "REQUIRED" },
      ]
    },
    { option_name = "TIMEZONE_FILE_AUTOUPGRADE" },
    { option_name = "STATSPACK" },
  ]
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
  multi_az               = false  # SQL Server Multi-AZ uses Always On, set separately
  db_subnet_group_name   = "prod-db-subnet-group"
  vpc_security_group_ids = ["sg-0dd"]
  kms_key_id             = module.kms.key_arn
  allocated_storage      = 200
  storage_type           = "gp3"
  storage_throughput     = 250
  backup_retention_period = 14
  deletion_protection    = true
  enabled_cloudwatch_logs_exports = ["error", "agent"]
  # SQL Server option group: Agent + TDE + Native Backup
  create_option_group               = true
  option_group_engine_name          = "sqlserver-ee"
  option_group_major_engine_version = "15.00"
  options = [
    # Enable SQL Server Agent for scheduled jobs and maintenance plans
    { option_name = "SQLSERVER_AGENT" },
    # Transparent Data Encryption — encrypts data files at rest
    { option_name = "TRANSPARENT_DATA_ENCRYPT" },
    # Native Backup & Restore — backup/restore directly to/from S3
    {
      option_name = "NATIVE_SRVR_BACKUPS"
      option_settings = [
        { name = "IAM_ROLE_ARN", value = "arn:aws:iam::123456789012:role/sqlserver-s3-backup-role" }
      ]
    },
  ]
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

