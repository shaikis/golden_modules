primary_region = "us-east-1"
dr_region      = "us-west-2"
environment    = "prod"
project        = "myproject"
owner          = "platform"
cost_center    = "engineering"

engine_version = "16.2"
db_name        = "appdb"
username       = "dbadmin"

primary_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/prod-aurora-pg-primary-key"
dr_kms_key_arn      = "arn:aws:kms:us-west-2:123456789012:key/prod-aurora-pg-dr-key"

# Primary — 3 instances (1 writer + 2 readers), multiple SGs
primary_subnet_group_name = "prod-aurora-subnet-group"
primary_security_group_ids = [
  "sg-0prodapp1111",
  "sg-0prodmon2222",
  "sg-0prodadmin3333",
]
primary_instance_count = 3
primary_instance_class = "db.r6g.xlarge"

# DR — us-west-2, pre-created equivalent SGs
dr_subnet_group_name = "prod-dr-aurora-subnet-group"
dr_security_group_ids = [
  "sg-0drapp4444",
  "sg-0drmon5555",
]
dr_instance_count = 2
dr_instance_class = "db.r6g.large"

backup_retention_period         = 30
skip_final_snapshot             = false
deletion_protection             = true
monitoring_interval             = 60
performance_insights_enabled    = true
enabled_cloudwatch_logs_exports = ["postgresql"]

create_secondary_region = true
