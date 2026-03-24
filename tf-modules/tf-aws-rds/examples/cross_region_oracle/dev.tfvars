primary_region = "us-east-1"
dr_region      = "us-west-2"
environment    = "dev"
project        = "myproject"
owner          = "platform"
cost_center    = "engineering"

oracle_edition         = "oracle-se2"
engine_version         = "19.0.0.0.ru-2024-01.rur-2024-01.r1"
instance_class         = "db.t3.medium"
license_model          = "bring-your-own-license"
character_set_name     = "AL32UTF8"
parameter_group_family = "oracle-se2-19"
username               = "admin"

allocated_storage     = 100
max_allocated_storage = 500
storage_type          = "gp3"

primary_subnet_group_name  = "dev-rds-subnet-group"
primary_security_group_ids = ["sg-0devdb1234"]
multi_az                   = false

backup_retention_period         = 1
skip_final_snapshot             = true
deletion_protection             = false
monitoring_interval             = 0
performance_insights_enabled    = false
enabled_cloudwatch_logs_exports = ["alert"]

enable_automated_backup_replication = false
create_cross_region_replica         = false
