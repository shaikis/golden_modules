primary_region = "us-east-1"
dr_region      = "us-west-2"
environment    = "dev"
project        = "myproject"
owner          = "platform"
cost_center    = "engineering"

engine_version         = "16.2"
instance_class         = "db.t3.micro"
parameter_group_family = "postgres16"
db_name                = "appdb"
username               = "dbadmin"

allocated_storage     = 20
max_allocated_storage = 100
storage_type          = "gp3"

primary_subnet_group_name  = "dev-rds-subnet-group"
primary_security_group_ids = ["sg-0devdb1234"]
multi_az                   = false

backup_retention_period         = 1
skip_final_snapshot             = true
deletion_protection             = false
monitoring_interval             = 0
performance_insights_enabled    = false
enabled_cloudwatch_logs_exports = ["postgresql"]

enable_automated_backup_replication = false
create_cross_region_replica         = false
