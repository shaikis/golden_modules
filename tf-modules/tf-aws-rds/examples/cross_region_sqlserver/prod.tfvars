primary_region = "us-east-1"
dr_region      = "us-west-2"
environment    = "prod"
project        = "myproject"
owner          = "platform"
cost_center    = "engineering"

sqlserver_edition      = "sqlserver-ee"
engine_version         = "15.00"
instance_class         = "db.r6i.2xlarge"
license_model          = "bring-your-own-license" # use existing EA/SA license
timezone               = "UTC"
parameter_group_family = "sqlserver-ee-15.0"
username               = "admin"

allocated_storage     = 500
max_allocated_storage = 5000
storage_type          = "io1"
iops                  = 16000

primary_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/prod-mssql-primary-key"
dr_kms_key_arn      = "arn:aws:kms:us-west-2:123456789012:key/prod-mssql-dr-key"

primary_subnet_group_name  = "prod-rds-subnet-group"
primary_security_group_ids = ["sg-0proddb1234"]
multi_az                   = true

backup_retention_period          = 30
skip_final_snapshot              = false
final_snapshot_identifier_prefix = "prod-mssql-final"
deletion_protection              = true
monitoring_interval              = 60
performance_insights_enabled     = true
enabled_cloudwatch_logs_exports  = ["agent", "error"]

# SQL Server does NOT support cross-region read replicas
# Use backup replication for DR + Multi-AZ for HA within region
enable_automated_backup_replication           = true
automated_backup_replication_retention_period = 14
automated_backup_replication_kms_key_arn      = "arn:aws:kms:us-west-2:123456789012:key/prod-mssql-dr-key"
