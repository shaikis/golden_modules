# ============================================================
# EFS Basic — dev environment
# ============================================================
region      = "us-east-1"
environment = "dev"
project     = "myproject"
owner       = "platform"
cost_center = "engineering"

# Feature toggles (enable/disable as needed)
create                  = true
create_security_group   = true
enable_lifecycle_policy = true
enable_backup_policy    = true
enable_replication      = false # not needed in dev

# Core settings
encrypted        = true
kms_key_arn      = null # uses AWS-managed key in dev
performance_mode = "generalPurpose"
throughput_mode  = "elastic"

# Lifecycle — move to IA after 30 days, recall on access
transition_to_ia                    = "AFTER_30_DAYS"
transition_to_primary_storage_class = "AFTER_1_ACCESS"

# Network — shared dev/staging VPC
vpc_id = "vpc-0dev1234567890abc"
subnet_ids = [
  "subnet-0dev111aaa",
  "subnet-0dev222bbb",
]
allowed_cidr_blocks = ["10.0.0.0/8"]

tags = {
  Terraform = "true"
}
