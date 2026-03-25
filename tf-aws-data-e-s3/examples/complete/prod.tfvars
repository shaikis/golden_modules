aws_region  = "us-east-1"
environment = "prod"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-200"
tags        = { DataClassification = "Confidential", Compliance = "SOC2" }

kms_name        = "s3-app-data"
kms_name_prefix = "company"

log_bucket_name   = "company-prod-access-logs"
log_bucket_owner  = "infra"
log_sse_algorithm = "AES256"

bucket_name        = "company-prod-app-data"
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
      { days = 30, storage_class = "STANDARD_IA" },
      { days = 90, storage_class = "GLACIER" },
      { days = 365, storage_class = "DEEP_ARCHIVE" },
    ]
    noncurrent_version_expiration = {
      noncurrent_days           = 90
      newer_noncurrent_versions = 3
    }
  }
]

intelligent_tiering_configurations = [
  {
    name = "entire-bucket"
    tierings = [
      { access_tier = "ARCHIVE_ACCESS", days = 90 },
      { access_tier = "DEEP_ARCHIVE_ACCESS", days = 180 },
    ]
  }
]
