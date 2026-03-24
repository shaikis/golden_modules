primary_region = "us-east-1"
dr_region      = "us-west-2"
environment    = "staging"
project        = "myproject"
owner          = "platform"
cost_center    = "engineering"

engine_version         = "10.11"
instance_class         = "db.t3.small"
parameter_group_family = "mariadb10.11"
db_name                = "appdb"
username               = "admin"

allocated_storage     = 50
max_allocated_storage = 200
storage_type          = "gp3"

primary_subnet_group_name  = "staging-rds-subnet-group"
primary_security_group_ids = ["sg-0stagingdb1234"]
multi_az                   = false

backup_retention_period         = 7
skip_final_snapshot             = true
deletion_protection             = false
monitoring_interval             = 0
performance_insights_enabled    = false
enabled_cloudwatch_logs_exports = ["error", "slowquery"]

enable_automated_backup_replication           = true
automated_backup_replication_retention_period = 7
automated_backup_replication_kms_key_arn      = null
create_cross_region_replica                   = false
