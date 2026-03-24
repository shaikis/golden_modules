# ============================================================
# EFS Basic — staging environment (shares dev VPC)
# ============================================================
region      = "us-east-1"
environment = "staging"
project     = "myproject"
owner       = "platform"
cost_center = "engineering"

# Feature toggles
create                  = true
create_security_group   = true
enable_lifecycle_policy = true
enable_backup_policy    = true
enable_replication      = false

# Core
encrypted        = true
kms_key_arn      = null
performance_mode = "generalPurpose"
throughput_mode  = "elastic"

# Lifecycle
transition_to_ia                    = "AFTER_30_DAYS"
transition_to_primary_storage_class = "AFTER_1_ACCESS"

# Network — SAME shared VPC as dev, different subnets
vpc_id = "vpc-0dev1234567890abc"
subnet_ids = [
  "subnet-0stg111aaa",
  "subnet-0stg222bbb",
]
allowed_cidr_blocks = ["10.0.0.0/8"]

tags = {
  Terraform = "true"
}
