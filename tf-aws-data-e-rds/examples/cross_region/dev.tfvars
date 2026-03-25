# ============================================================
# RDS Cross-Region — dev environment
# ============================================================
# In dev: no cross-region replication (cost saving).
# Both patterns disabled.

primary_region = "us-east-1"
dr_region      = "us-west-2"

name        = "myapp"
environment = "dev"
project     = "myproject"
owner       = "platform"
cost_center = "engineering"

# Engine
engine         = "mysql"
engine_version = "8.0"
instance_class = "db.t3.micro"

# Database
db_name  = "myappdb"
username = "admin"
port     = 3306

# Credentials via Secrets Manager
manage_master_user_password = true

# Storage
allocated_storage     = 20
max_allocated_storage = 100
storage_type          = "gp3"

# Primary network — shared dev/staging VPC
primary_subnet_group_name  = "dev-rds-subnet-group"
primary_security_group_ids = ["sg-0devdb1234"]
multi_az                   = false # single-AZ in dev to save cost

# Backup
backup_retention_period = 1 # minimum for replication compatibility
backup_window           = "02:00-03:00"
maintenance_window      = "Mon:03:00-Mon:04:00"
skip_final_snapshot     = true  # skip final snapshot in dev
deletion_protection     = false # allow deletion in dev

# Monitoring
monitoring_interval          = 0 # disabled in dev
performance_insights_enabled = false

# Cross-region toggles — BOTH disabled in dev
enable_automated_backup_replication = false
create_cross_region_replica         = false

tags = {
  Terraform = "true"
}
