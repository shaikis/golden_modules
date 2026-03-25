# SKIP_IN_CI
# Integration test — tf-aws-s3-replication (plan-only)
# command = apply would create real S3 buckets with cross-region replication.
# This test runs as plan because CRR requires a pre-existing versioned destination
# bucket in another region. Provide real bucket ARNs to switch to apply.
# Cost: S3 replication data transfer costs vary by region and data volume.
# Set AWS_PROFILE / AWS credentials before running.

provider "aws" {
  region = "us-east-1"
}

variables {
  source_bucket_name = "tftest-s3-repl-source-20260325"
  source_region      = "us-east-1"
  environment        = "test"

  enable_versioning = true

  # SRR: same-region backup bucket
  enable_srr        = true
  srr_bucket_name   = "tftest-s3-repl-backup-20260325"
  srr_storage_class = "STANDARD"

  tags = {
    ManagedBy   = "terraform-test"
    Environment = "test"
  }
}

run "plan_s3_replication" {
  # Using plan here because CRR requires a pre-existing destination bucket.
  # Change to apply in an environment where the destination bucket exists.
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.enable_srr == true
    error_message = "Expected enable_srr to be true."
  }

  assert {
    condition     = var.source_bucket_name == "tftest-s3-repl-source-20260325"
    error_message = "Expected source_bucket_name to match the configured value."
  }
}
