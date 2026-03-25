# Integration test — basic S3 bucket creation for tf-aws-data-e-s3
# command = apply: creates a real S3 bucket in AWS.
# SKIP_IN_CI

# Prerequisites:
#   export AWS_ACCESS_KEY_ID="..."
#   export AWS_SECRET_ACCESS_KEY="..."
#   export AWS_DEFAULT_REGION="us-east-1"
#
# Cost: S3 free tier covers 5 GB storage — integration tests are
# effectively free for normal usage.

# Provider configuration for the integration environment.
provider "aws" {
  region = "us-east-1"
}

run "create_basic_bucket" {
  # SKIP_IN_CI
  command = apply

  module {
    source = "../../"
  }

  variables {
    # Bucket names must be globally unique; append your account-specific suffix.
    bucket_name  = "integ-s3-test-123456789012"
    environment  = "test"
    force_destroy = true

    versioning_enabled = true
    sse_algorithm      = "AES256"

    # BYO encryption: kms_master_key_id = null uses AWS-managed S3 key.
    kms_master_key_id = null

    # All feature gates off by default.
    lifecycle_rules           = []
    replication_configuration = null
    enable_access_logging     = false

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true

    tags = {
      Purpose = "integration-test"
    }
  }

  assert {
    condition     = output.bucket_arn != ""
    error_message = "bucket_arn output must be set after a successful apply."
  }

  assert {
    condition     = output.bucket_id != ""
    error_message = "bucket_id output must be set after a successful apply."
  }
}
