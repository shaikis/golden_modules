aws_region  = "us-east-1"
environment = "staging"
project     = "platform"
owner       = "dev-team"
cost_center = "CC-150"
tags        = { DataClassification = "Internal" }

kms_name        = "s3-app-data"
kms_name_prefix = ""

log_bucket_name   = "company-staging-access-logs"
log_bucket_owner  = "dev-team"
log_sse_algorithm = "AES256"

bucket_name        = "company-staging-app-data"
name_prefix        = "company"
force_destroy      = false
object_ownership   = "BucketOwnerEnforced"
versioning_enabled = true
mfa_delete         = false
sse_algorithm      = "aws:kms"
bucket_key_enabled = true

block_public_acls       = true
block_public_policy     = true
ignore_public_acls      = true
restrict_public_buckets = true

enable_access_logging = true
access_log_prefix     = "app-data/"

attach_deny_insecure_transport_policy = true
attach_require_latest_tls_policy      = true

lifecycle_rules = [
  {
    id      = "transition-to-ia"
    enabled = true
    transition = [
      { days = 60, storage_class = "STANDARD_IA" },
      { days = 180, storage_class = "GLACIER" },
    ]
    noncurrent_version_expiration = {
      noncurrent_days           = 90
      newer_noncurrent_versions = 3
    }
  }
]

intelligent_tiering_configurations = []
