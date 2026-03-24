primary_region = "us-east-1"
dr_region      = "us-west-2"
environment    = "dev"
project        = "myproject"
owner          = "platform"
cost_center    = "engineering"

sqlserver_edition      = "sqlserver-se"
engine_version         = "15.00"
instance_class         = "db.m5.xlarge" # minimum class for SQL Server SE
license_model          = "license-included"
timezone               = "UTC"
parameter_group_family = "sqlserver-se-15.0"
username               = "admin"

allocated_storage     = 200
max_allocated_storage = 1000
storage_type          = "gp3"

primary_subnet_group_name  = "dev-rds-subnet-group"
primary_security_group_ids = ["sg-0devdb1234"]
multi_az                   = false

backup_retention_period         = 1
skip_final_snapshot             = true
deletion_protection             = false
monitoring_interval             = 0
performance_insights_enabled    = false
enabled_cloudwatch_logs_exports = ["error"]

# SQL Server does NOT support cross-region read replicas
enable_automated_backup_replication = false
