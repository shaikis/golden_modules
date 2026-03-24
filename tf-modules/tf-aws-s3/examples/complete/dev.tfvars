aws_region  = "us-east-1"
environment = "dev"
project     = "platform"
owner       = "dev-team"
cost_center = "CC-100"
tags        = { DataClassification = "Internal" }

kms_name        = "s3-app-data"
kms_name_prefix = ""

log_bucket_name   = "company-dev-access-logs"
log_bucket_owner  = "dev-team"
log_sse_algorithm = "AES256"

bucket_name        = "company-dev-app-data"
name_prefix        = "company"
force_destroy      = true
object_ownership   = "BucketOwnerEnforced"
versioning_enabled = false
mfa_delete         = false
sse_algorithm      = "AES256"
bucket_key_enabled = false

block_public_acls       = true
block_public_policy     = true
ignore_public_acls      = true
restrict_public_buckets = true

enable_access_logging = false
access_log_prefix     = "app-data/"

attach_deny_insecure_transport_policy = true
attach_require_latest_tls_policy      = true

lifecycle_rules                    = []
intelligent_tiering_configurations = []
