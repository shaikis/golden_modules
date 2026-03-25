# ============================================================
# RDS Cross-Region — prod environment
# ============================================================
# In prod: BOTH patterns enabled:
#   Pattern 1: automated backup replication (compliance + PITR in DR)
#   Pattern 2: live cross-region read replica (fast DR failover + read offload)

primary_region = "us-east-1"
dr_region      = "us-west-2"

name        = "myapp"
environment = "prod"
project     = "myproject"
owner       = "platform"
cost_center = "engineering"

# Engine
engine         = "mysql"
engine_version = "8.0"
instance_class = "db.r6g.xlarge"

# Database
db_name  = "myappdb"
username = "admin"
port     = 3306

manage_master_user_password = true

# Storage
allocated_storage     = 500
max_allocated_storage = 2000
storage_type          = "io1"
iops                  = 10000

# Encryption — prod uses CMK in both regions
primary_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/prod-rds-primary-key"
dr_kms_key_arn      = "arn:aws:kms:us-west-2:123456789012:key/prod-rds-dr-key"

# Primary network — dedicated prod VPC
primary_subnet_group_name  = "prod-rds-subnet-group"
primary_security_group_ids = ["sg-0proddb1234"]
multi_az                   = true # HA in prod

# DR network — in us-west-2 (pre-created)
dr_subnet_group_name  = "prod-dr-rds-subnet-group"
dr_security_group_ids = ["sg-0drdb5678"]

# Backup — 30 days retention in prod
backup_retention_period          = 30
backup_window                    = "02:00-03:00"
maintenance_window               = "Mon:03:00-Mon:04:00"
skip_final_snapshot              = false
final_snapshot_identifier_prefix = "prod-final"
deletion_protection              = true

# Monitoring
monitoring_interval             = 60
performance_insights_enabled    = true
enabled_cloudwatch_logs_exports = ["error", "slowquery", "audit"]

# Cross-region toggles — BOTH enabled in prod

# Pattern 1: Automated backup replication for point-in-time recovery in DR
enable_automated_backup_replication           = true
automated_backup_replication_retention_period = 14
automated_backup_replication_kms_key_arn      = "arn:aws:kms:us-west-2:123456789012:key/prod-rds-dr-key"

# Pattern 2: Live read replica in DR for fast failover
create_cross_region_replica = true
replica_instance_class      = "db.r6g.large" # can be smaller than primary

tags = {
  Terraform   = "true"
  Criticality = "high"
  DR          = "enabled"
}
