# ============================================================
# RDS Cross-Region — staging environment
# ============================================================
# In staging: enable automated backup replication only.
# No live replica (use backup replication for DR testing).

primary_region = "us-east-1"
dr_region      = "us-west-2"

name        = "myapp"
environment = "staging"
project     = "myproject"
owner       = "platform"
cost_center = "engineering"

# Engine
engine         = "mysql"
engine_version = "8.0"
instance_class = "db.t3.small"

# Database
db_name  = "myappdb"
username = "admin"
port     = 3306

manage_master_user_password = true

# Storage
allocated_storage     = 50
max_allocated_storage = 200
storage_type          = "gp3"

# Primary network — shared dev/staging VPC
primary_subnet_group_name  = "staging-rds-subnet-group"
primary_security_group_ids = ["sg-0stagingdb1234"]
multi_az                   = false

# Backup
backup_retention_period = 7
backup_window           = "02:00-03:00"
maintenance_window      = "Mon:03:00-Mon:04:00"
skip_final_snapshot     = true
deletion_protection     = false

# Monitoring
monitoring_interval          = 0
performance_insights_enabled = false

# Cross-region toggles
# Pattern 1: backup replication enabled for DR testing
enable_automated_backup_replication           = true
automated_backup_replication_retention_period = 7
automated_backup_replication_kms_key_arn      = null # AWS-managed key in DR region

# Pattern 2: no live replica in staging
create_cross_region_replica = false

tags = {
  Terraform = "true"
}
