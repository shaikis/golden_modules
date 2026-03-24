# ============================================================
# EFS Complete — prod environment (dedicated VPC + DR replication)
# ============================================================
region      = "us-east-1"
environment = "prod"
project     = "myproject"
owner       = "platform"
cost_center = "engineering"

# Feature toggles — all enabled in prod
create                  = true
create_security_group   = true
enable_lifecycle_policy = true
enable_backup_policy    = true
enable_replication      = true # cross-region DR to us-west-2

# Core — prod uses CMK
encrypted        = true
kms_key_arn      = "arn:aws:kms:us-east-1:123456789012:key/prod-efs-key-id"
performance_mode = "generalPurpose"
throughput_mode  = "elastic"

# Lifecycle — longer retention in prod
transition_to_ia                    = "AFTER_60_DAYS"
transition_to_primary_storage_class = "AFTER_1_ACCESS"

# Network — dedicated prod VPC (3 AZs for HA)
vpc_id = "vpc-0prod1234567890abc"
subnet_ids = [
  "subnet-0prod111aaa",
  "subnet-0prod222bbb",
  "subnet-0prod333ccc",
]
allowed_cidr_blocks = ["10.100.0.0/16"]

# Access points — granular app segregation in prod
access_points = {
  app = {
    path        = "/app"
    owner_uid   = 1000
    owner_gid   = 1000
    permissions = "750"
    posix_uid   = 1000
    posix_gid   = 1000
  }
  logs = {
    path        = "/logs"
    owner_uid   = 0
    owner_gid   = 0
    permissions = "750"
    posix_uid   = 0
    posix_gid   = 0
  }
  config = {
    path        = "/config"
    owner_uid   = 0
    owner_gid   = 0
    permissions = "700"
    posix_uid   = 0
    posix_gid   = 0
  }
}

# Cross-region replication → us-west-2 DR region
replication_destination_region      = "us-west-2"
replication_destination_kms_key_arn = "arn:aws:kms:us-west-2:123456789012:key/dr-efs-key-id"

tags = {
  Terraform   = "true"
  Criticality = "high"
  DR          = "enabled"
}
