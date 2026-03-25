# SKIP_IN_CI
# Integration test — tf-aws-s3
# command = apply; creates a real S3 bucket.
# Cost: S3 storage is free for the first 5 GB/month under the Free Tier.
#       No data is written so storage cost is effectively $0.
# Set AWS_PROFILE / AWS credentials before running.

provider "aws" {
  region = "us-east-1"
}

variables {
  bucket_name = "tftest-s3-basic-20260325"
  environment = "test"

  versioning_enabled = true
  sse_algorithm      = "AES256"

  force_destroy = true # allow clean teardown during tests

  tags = {
    ManagedBy   = "terraform-test"
    Environment = "test"
  }
}

run "create_bucket" {
  command = apply

  module {
    source = "../../"
  }

  assert {
    condition     = output.bucket_arn != null && output.bucket_arn != ""
    error_message = "Expected bucket_arn to be set after apply."
  }

  assert {
    condition     = output.bucket_id != null && output.bucket_id != ""
    error_message = "Expected bucket_id to be set after apply."
  }

  assert {
    condition     = output.bucket_name == "tftest-s3-basic-20260325"
    error_message = "Expected bucket_name to match the input variable."
  }
}
