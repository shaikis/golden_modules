primary_region = "us-east-1"
dr_region      = "us-west-2"
environment    = "prod"
project        = "myproject"
owner          = "platform"
cost_center    = "engineering"

oracle_edition         = "oracle-ee"
engine_version         = "19.0.0.0.ru-2024-01.rur-2024-01.r1"
instance_class         = "db.r6g.xlarge"
license_model          = "bring-your-own-license"
character_set_name     = "AL32UTF8"
parameter_group_family = "oracle-ee-19"
username               = "admin"

allocated_storage     = 500
max_allocated_storage = 5000
storage_type          = "io1"
iops                  = 16000

primary_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/prod-oracle-primary-key"
dr_kms_key_arn      = "arn:aws:kms:us-west-2:123456789012:key/prod-oracle-dr-key"

primary_subnet_group_name  = "prod-rds-subnet-group"
primary_security_group_ids = ["sg-0proddb1234"]
multi_az                   = true

dr_subnet_group_name  = "prod-dr-rds-subnet-group"
dr_security_group_ids = ["sg-0drdb5678"]

backup_retention_period          = 30
skip_final_snapshot              = false
final_snapshot_identifier_prefix = "prod-oracle-final"
deletion_protection              = true
monitoring_interval              = 60
performance_insights_enabled     = true
enabled_cloudwatch_logs_exports  = ["alert", "audit", "listener", "trace"]

enable_automated_backup_replication           = true
automated_backup_replication_retention_period = 14
automated_backup_replication_kms_key_arn      = "arn:aws:kms:us-west-2:123456789012:key/prod-oracle-dr-key"
create_cross_region_replica                   = true
replica_instance_class                        = "db.r6g.large"
