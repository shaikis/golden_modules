# ============================================================
# EFS Complete — dev environment
# ============================================================
region      = "us-east-1"
environment = "dev"
project     = "myproject"
owner       = "platform"
cost_center = "engineering"

# Feature toggles
create                  = true
create_security_group   = true
enable_lifecycle_policy = true
enable_backup_policy    = true
enable_replication      = false # disabled in dev

# Core
encrypted        = true
kms_key_arn      = null # AWS-managed key in dev
performance_mode = "generalPurpose"
throughput_mode  = "elastic"

# Lifecycle
transition_to_ia                    = "AFTER_30_DAYS"
transition_to_primary_storage_class = "AFTER_1_ACCESS"

# Network — shared dev VPC
vpc_id = "vpc-0dev1234567890abc"
subnet_ids = [
  "subnet-0dev111aaa",
  "subnet-0dev222bbb",
]
allowed_cidr_blocks = ["10.0.0.0/8"]

# Access points — one per application component
access_points = {
  app = {
    path        = "/app"
    owner_uid   = 1000
    owner_gid   = 1000
    permissions = "755"
    posix_uid   = 1000
    posix_gid   = 1000
  }
  logs = {
    path        = "/logs"
    owner_uid   = 0
    owner_gid   = 0
    permissions = "777"
    posix_uid   = 0
    posix_gid   = 0
  }
}

tags = {
  Terraform = "true"
}
