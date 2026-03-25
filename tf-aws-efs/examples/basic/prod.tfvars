# ============================================================
# EFS Basic — prod environment (dedicated VPC + replication)
# ============================================================
region      = "us-east-1"
environment = "prod"
project     = "myproject"
owner       = "platform"
cost_center = "engineering"

# Feature toggles — prod has replication enabled
create                  = true
create_security_group   = true
enable_lifecycle_policy = true
enable_backup_policy    = true
enable_replication      = true # cross-region DR

# Core — prod uses CMK
encrypted        = true
kms_key_arn      = "arn:aws:kms:us-east-1:123456789012:key/prod-efs-key-id"
performance_mode = "generalPurpose"
throughput_mode  = "elastic"

# Lifecycle
transition_to_ia                    = "AFTER_60_DAYS"
transition_to_primary_storage_class = "AFTER_1_ACCESS"

# Network — dedicated prod VPC
vpc_id = "vpc-0prod1234567890abc"
subnet_ids = [
  "subnet-0prod111aaa",
  "subnet-0prod222bbb",
  "subnet-0prod333ccc",
]
allowed_cidr_blocks = ["10.100.0.0/16"]

# Cross-region replication → us-west-2 (DR region)
replication_destination_region      = "us-west-2"
replication_destination_kms_key_arn = "arn:aws:kms:us-west-2:123456789012:key/dr-efs-key-id"

tags = {
  Terraform   = "true"
  Criticality = "high"
}
