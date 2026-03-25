# Unit tests — variable validation for tf-aws-s3-replication
# command = plan; no real AWS resources are created.

run "valid_srr_storage_class_standard" {
  command = plan

  variables {
    source_bucket_name = "my-test-source-bucket-srr-12345"
    source_region      = "us-east-1"
    enable_srr         = true
    srr_bucket_name    = "my-test-source-bucket-srr-backup-12345"
    srr_storage_class  = "STANDARD"
  }

  assert {
    condition     = var.srr_storage_class == "STANDARD"
    error_message = "srr_storage_class 'STANDARD' should be accepted."
  }
}

run "valid_srr_storage_class_standard_ia" {
  command = plan

  variables {
    source_bucket_name = "my-test-source-bucket-ia-12345"
    source_region      = "us-east-1"
    enable_srr         = true
    srr_bucket_name    = "my-test-source-bucket-ia-backup-12345"
    srr_storage_class  = "STANDARD_IA"
  }

  assert {
    condition     = var.srr_storage_class == "STANDARD_IA"
    error_message = "srr_storage_class 'STANDARD_IA' should be accepted."
  }
}

run "valid_crr_destination_storage_class" {
  command = plan

  variables {
    source_bucket_name = "my-test-source-bucket-crr-12345"
    source_region      = "us-east-1"
    enable_crr         = true
    crr_destinations = {
      us_west = {
        bucket_arn    = "arn:aws:s3:::my-test-dest-bucket-us-west-12345"
        region        = "us-west-2"
        storage_class = "STANDARD"
      }
    }
  }

  assert {
    condition     = var.crr_destinations["us_west"].storage_class == "STANDARD"
    error_message = "CRR destination storage_class 'STANDARD' should be accepted."
  }
}

run "no_replication_enabled_no_destinations" {
  command = plan

  variables {
    source_bucket_name = "my-test-source-bucket-norepl-12345"
    source_region      = "us-east-1"
    enable_srr         = false
    enable_crr         = false
  }

  assert {
    condition     = var.enable_srr == false && var.enable_crr == false
    error_message = "Both enable_srr and enable_crr should be false when not set."
  }
}

run "valid_source_lifecycle_rule" {
  command = plan

  variables {
    source_bucket_name = "my-test-source-bucket-lc-12345"
    source_region      = "us-east-1"
    source_lifecycle_rules = [
      {
        id                                 = "expire-noncurrent"
        enabled                            = true
        noncurrent_version_expiration_days = 90
      }
    ]
  }

  assert {
    condition     = length(var.source_lifecycle_rules) == 1
    error_message = "Expected 1 source lifecycle rule to be configured."
  }
}
