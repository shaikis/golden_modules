# ============================================================
# Aurora MySQL — staging (single region, HA writer+reader)
# ============================================================
primary_region = "us-east-1"
dr_region      = "us-west-2"
environment    = "staging"
project        = "myproject"
owner          = "platform"
cost_center    = "engineering"

engine_version = "8.0.mysql_aurora.3.04.0"
db_name        = "appdb"
username       = "admin"

primary_subnet_group_name = "staging-aurora-subnet-group"
# Multiple security groups example: app SG + bastion SG + monitoring SG
primary_security_group_ids = [
  "sg-0appdb1234",
  "sg-0bastion5678",
]

primary_instance_count = 2 # writer + 1 reader
primary_instance_class = "db.t3.medium"

backup_retention_period         = 7
skip_final_snapshot             = true
deletion_protection             = false
monitoring_interval             = 0
performance_insights_enabled    = false
enabled_cloudwatch_logs_exports = ["error", "slowquery"]

create_secondary_region = false
