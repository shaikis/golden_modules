# ============================================================
# Aurora MySQL — dev (single region, no DR)
# ============================================================
primary_region = "us-east-1"
dr_region      = "us-west-2"
environment    = "dev"
project        = "myproject"
owner          = "platform"
cost_center    = "engineering"

engine_version = "8.0.mysql_aurora.3.04.0"
db_name        = "appdb"
username       = "admin"

# Primary network — shared dev VPC
primary_subnet_group_name  = "dev-aurora-subnet-group"
primary_security_group_ids = ["sg-0devdb1234"] # single SG in dev

# 1 writer only in dev to save cost
primary_instance_count = 1
primary_instance_class = "db.t3.medium"

backup_retention_period         = 1
skip_final_snapshot             = true
deletion_protection             = false
monitoring_interval             = 0
performance_insights_enabled    = false
enabled_cloudwatch_logs_exports = ["error"]

# No DR in dev
create_secondary_region = false
