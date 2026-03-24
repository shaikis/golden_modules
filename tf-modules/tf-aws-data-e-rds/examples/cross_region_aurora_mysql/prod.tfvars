# ============================================================
# Aurora MySQL — prod (Global Database with DR secondary)
# ============================================================
primary_region = "us-east-1"
dr_region      = "us-west-2"
environment    = "prod"
project        = "myproject"
owner          = "platform"
cost_center    = "engineering"

engine_version = "8.0.mysql_aurora.3.04.0"
db_name        = "appdb"
username       = "admin"

primary_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/prod-aurora-mysql-primary-key"
dr_kms_key_arn      = "arn:aws:kms:us-west-2:123456789012:key/prod-aurora-mysql-dr-key"

# Primary network — dedicated prod VPC
primary_subnet_group_name = "prod-aurora-subnet-group"
# Multiple security groups: app tier SG + monitoring SG + admin SG
primary_security_group_ids = [
  "sg-0prodapp1111",
  "sg-0prodmon2222",
  "sg-0prodadmin3333",
]

primary_instance_count = 3 # 1 writer + 2 readers for HA
primary_instance_class = "db.r6g.xlarge"

# DR network — us-west-2 (pre-created)
# IMPORTANT: These must be SGs from the DR VPC (us-west-2), NOT from primary VPC
dr_subnet_group_name = "prod-dr-aurora-subnet-group"
dr_security_group_ids = [
  "sg-0drapp4444", # equivalent app-tier SG in DR VPC
  "sg-0drmon5555", # equivalent monitoring SG in DR VPC
]

dr_instance_count = 2 # 1 writer + 1 reader in DR
dr_instance_class = "db.r6g.large"

backup_retention_period         = 30
skip_final_snapshot             = false
deletion_protection             = true
monitoring_interval             = 60
performance_insights_enabled    = true
enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

# Enable secondary region for DR
create_secondary_region = true
