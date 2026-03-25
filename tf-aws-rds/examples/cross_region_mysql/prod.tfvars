# ============================================================
# MySQL Cross-Region — prod (both patterns enabled)
# ============================================================
primary_region = "us-east-1"
dr_region      = "us-west-2"
environment    = "prod"
project        = "myproject"
owner          = "platform"
cost_center    = "engineering"

engine_version         = "8.0"
instance_class         = "db.r6g.xlarge"
parameter_group_family = "mysql8.0"

db_name  = "appdb"
username = "admin"

allocated_storage     = 500
max_allocated_storage = 2000
storage_type          = "io1"
iops                  = 10000

primary_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/prod-mysql-primary-key"
dr_kms_key_arn      = "arn:aws:kms:us-west-2:123456789012:key/prod-mysql-dr-key"

primary_subnet_group_name  = "prod-rds-subnet-group"
primary_security_group_ids = ["sg-0proddb1234"]
multi_az                   = true

dr_subnet_group_name  = "prod-dr-rds-subnet-group"
dr_security_group_ids = ["sg-0drdb5678"]

backup_retention_period          = 30
backup_window                    = "02:00-03:00"
maintenance_window               = "Mon:03:00-Mon:04:00"
skip_final_snapshot              = false
final_snapshot_identifier_prefix = "prod-mysql-final"
deletion_protection              = true

monitoring_interval             = 60
performance_insights_enabled    = true
enabled_cloudwatch_logs_exports = ["error", "general", "slowquery", "audit"]

# Both patterns enabled in prod
enable_automated_backup_replication           = true
automated_backup_replication_retention_period = 14
automated_backup_replication_kms_key_arn      = "arn:aws:kms:us-west-2:123456789012:key/prod-mysql-dr-key"
create_cross_region_replica                   = true
replica_instance_class                        = "db.r6g.large"
