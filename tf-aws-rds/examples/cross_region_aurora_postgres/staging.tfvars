primary_region = "us-east-1"
dr_region      = "us-west-2"
environment    = "staging"
project        = "myproject"
owner          = "platform"
cost_center    = "engineering"

engine_version = "16.2"
db_name        = "appdb"
username       = "dbadmin"

primary_subnet_group_name = "staging-aurora-subnet-group"
primary_security_group_ids = [
  "sg-0appdb1234",
  "sg-0bastion5678",
]

primary_instance_count = 2
primary_instance_class = "db.t3.medium"

backup_retention_period         = 7
skip_final_snapshot             = true
deletion_protection             = false
monitoring_interval             = 0
performance_insights_enabled    = false
enabled_cloudwatch_logs_exports = ["postgresql"]

create_secondary_region = false
